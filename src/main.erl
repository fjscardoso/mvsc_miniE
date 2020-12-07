-module(main).

-export([start/0, start/3, start/5]).

%Start with buffer size 10, 3 producers and 2 consumers with 50 jobs to produce per producer and 75 jobs to consume per consumer
start() ->
    start(10, 3, 2, 50, 75).

%Start 3 producers and 2 consumers with Producerjobs per producer and Consumerjobs per consumer
start(Buffersize, Producerjobs, Consumerjobs) ->
	start(Buffersize, 3, 2, Producerjobs, Consumerjobs).

%Start NProducers and NConsumers with ProducerJobs per producer and ConsumerJobs per consumer
start(Buffersize, NProducers, NConsumers, Producerjobs, Consumerjobs) ->
	Sup = supv:start(bb, [Buffersize]),
    startProducers(Sup, NProducers, Producerjobs),
    startConsumers(Sup, NConsumers, Consumerjobs).

%start producers with supervisor Sup, number of producers N, number of jobs per producer Jobs
startProducers(_,0,_) -> ok;
startProducers(Sup, N, Jobs) -> 
	producer:start(Sup, Jobs),
	startProducers(Sup, N-1, Jobs).

%start consumers with supervisor Sup, number of consumers N, number of jobs per consumer Jobs
startConsumers(_,0,_) -> ok;
startConsumers(Sup, N, Jobs) -> 
	consumer:start(Sup, Jobs),
	startConsumers(Sup, N-1, Jobs).

					