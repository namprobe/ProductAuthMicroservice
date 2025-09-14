using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ProductAuthMicroservice.Commons.Configs;
using ProductAuthMicroservice.Commons.Extensions;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RabbitMQ.Client.Exceptions;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using Polly;

namespace ProductAuthMicroservice.Commons.EventBus;

public class RabbitMQEventBus : IEventBus, IDisposable
{
    private readonly IRabbitMQConnection _connection;
    private readonly ILogger<RabbitMQEventBus> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly RabbitMQConfig _config;
    private readonly Dictionary<string, List<Type>> _handlers = new();
    private readonly List<Type> _eventTypes = new();
    private IChannel? _consumerChannel;
    private string? _queueName;

    public RabbitMQEventBus(
        IRabbitMQConnection connection,
        ILogger<RabbitMQEventBus> logger,
        IServiceProvider serviceProvider,
        IOptions<RabbitMQConfig> config)
    {
        _connection = connection;
        _logger = logger;
        _serviceProvider = serviceProvider;
        _config = config.Value;
        _consumerChannel = CreateConsumerChannel();
    }

    public async Task PublishAsync<T>(T @event, CancellationToken cancellationToken = default) where T : IntegrationEvent
    {
        if (!_connection.IsConnected)
        {
            _connection.TryConnect();
        }

        var policy = Policy.Handle<BrokerUnreachableException>()
            .Or<SocketException>()
            .WaitAndRetryAsync(_config.RetryCount, retryAttempt =>
                TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)), (ex, time) =>
                {
                    _logger.LogWarning(ex, "Could not publish event: {EventId} after {Timeout}s", @event.Id, $"{time.TotalSeconds:n1}");
                });

        var eventName = @event.GetType().Name;

        _logger.LogTrace("Creating RabbitMQ channel to publish event: {EventId} ({EventName})", @event.Id, eventName);

        using var channel = _connection.CreateChannel();
        
        await channel.ExchangeDeclareAsync(exchange: _config.ExchangeName, type: ExchangeType.Direct);

        var body = JsonSerializer.SerializeToUtf8Bytes(@event, @event.GetType(), new JsonSerializerOptions
        {
            WriteIndented = true
        });

        await policy.ExecuteAsync(async () =>
        {
            var properties = new BasicProperties
            {
                DeliveryMode = DeliveryModes.Persistent
            };

            _logger.LogTrace("Publishing event to RabbitMQ: {EventId}", @event.Id);

            await channel.BasicPublishAsync(
                exchange: _config.ExchangeName,
                routingKey: eventName,
                mandatory: true,
                basicProperties: properties,
                body: body,
                cancellationToken: cancellationToken);
        });
    }

    public void Subscribe<T, TH>()
        where T : IntegrationEvent
        where TH : class, IIntegrationEventHandler<T>
    {
        var eventName = GetEventKey<T>();
        DoInternalSubscription(eventName);

        _logger.LogInformation("Subscribing to event {EventName} with {EventHandler}", eventName, typeof(TH).GetGenericTypeName());

        if (!_handlers.ContainsKey(eventName))
        {
            _handlers[eventName] = new List<Type>();
        }

        _handlers[eventName].Add(typeof(TH));
        _eventTypes.Add(typeof(T));
    }

    public void Unsubscribe<T, TH>()
        where T : IntegrationEvent
        where TH : class, IIntegrationEventHandler<T>
    {
        var eventName = GetEventKey<T>();

        _logger.LogInformation("Unsubscribing from event {EventName}", eventName);

        if (_handlers.ContainsKey(eventName))
        {
            _handlers[eventName].Remove(typeof(TH));
            if (!_handlers[eventName].Any())
            {
                _handlers.Remove(eventName);
                var eventType = _eventTypes.SingleOrDefault(e => e.Name == eventName);
                if (eventType != null)
                {
                    _eventTypes.Remove(eventType);
                }
            }
        }
    }

    public void StartConsuming()
    {
        if (_consumerChannel != null)
        {
            var consumer = new AsyncEventingBasicConsumer(_consumerChannel);
            consumer.ReceivedAsync += Consumer_Received;

            _consumerChannel.BasicConsumeAsync(
                queue: _queueName!,
                autoAck: false,
                consumer: consumer);
        }
    }

    public void StopConsuming()
    {
        _consumerChannel?.CloseAsync();
    }

    private async Task Consumer_Received(object sender, BasicDeliverEventArgs eventArgs)
    {
        var eventName = eventArgs.RoutingKey;
        var message = Encoding.UTF8.GetString(eventArgs.Body.Span);

        try
        {
            await ProcessEvent(eventName, message);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error Processing message \"{Message}\"", message);
        }

        // Even on exception we take the message off the queue.
        // in a REAL WORLD app this should be handled with a Dead Letter Exchange (DLX). 
        // For more information see: https://www.rabbitmq.com/dlx.html
        await _consumerChannel!.BasicAckAsync(eventArgs.DeliveryTag, multiple: false);
    }

    private IChannel CreateConsumerChannel()
    {
        if (!_connection.IsConnected)
        {
            _connection.TryConnect();
        }

        _logger.LogTrace("Creating RabbitMQ consumer channel");

        var channel = _connection.CreateChannel();

        channel.ExchangeDeclareAsync(exchange: _config.ExchangeName, type: ExchangeType.Direct);

        var queueDeclareResult = channel.QueueDeclareAsync().GetAwaiter().GetResult();
        _queueName = queueDeclareResult.QueueName;

        channel.CallbackExceptionAsync += (sender, ea) =>
        {
            _logger.LogWarning(ea.Exception, "Recreating RabbitMQ consumer channel");
            _consumerChannel?.Dispose();
            _consumerChannel = CreateConsumerChannel();
            StartConsuming();
            return Task.CompletedTask;
        };

        return channel;
    }

    private void DoInternalSubscription(string eventName)
    {
        var containsKey = _handlers.ContainsKey(eventName);
        if (!containsKey)
        {
            if (!_connection.IsConnected)
            {
                _connection.TryConnect();
            }

            _consumerChannel?.QueueBindAsync(queue: _queueName!, exchange: _config.ExchangeName, routingKey: eventName);
        }
    }

    private async Task ProcessEvent(string eventName, string message)
    {
        _logger.LogTrace("Processing RabbitMQ event: {EventName}", eventName);

        if (_handlers.ContainsKey(eventName))
        {
            using var scope = _serviceProvider.CreateScope();
            var subscriptions = _handlers[eventName];

            foreach (var subscription in subscriptions)
            {
                var handler = scope.ServiceProvider.GetService(subscription);
                if (handler == null) continue;

                var eventType = _eventTypes.SingleOrDefault(t => t.Name == eventName);
                if (eventType == null) continue;

                var integrationEvent = JsonSerializer.Deserialize(message, eventType, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                var concreteType = typeof(IIntegrationEventHandler<>).MakeGenericType(eventType);
                await Task.Yield();
                await (Task)concreteType.GetMethod("Handle")!.Invoke(handler, new[] { integrationEvent, CancellationToken.None })!;
            }
        }
        else
        {
            _logger.LogWarning("No subscription for RabbitMQ event: {EventName}", eventName);
        }
    }

    private static string GetEventKey<T>()
    {
        return typeof(T).Name;
    }

    public void Dispose()
    {
        _consumerChannel?.Dispose();
    }
}
