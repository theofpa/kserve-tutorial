#hey -n 100 -c 10 -m POST -T "application/json" -host flower-sample.default.example.com -D ./input.json http://localhost:8080/v1/models/flower-sample:predict

# hey -n 10000 -c 10 -m POST -T "application/json" -host mnist.default.example.com -D ./mnist.json http://localhost:8080/v1/models/mnist:predict

# curl -X POST "http://localhost:6566/get-online-features" -d '{    "features": [      "driver_hourly_stats:conv_rate",      "driver_hourly_stats:acc_rate",      "driver_hourly_stats:avg_daily_trips"    ],    "entities": {      "driver_id": [1001, 1002, 1003]    }  }' | jq

hey -n 10000 -c 2 -q 1 -D ./torch_mnist_digit2.json -m POST -host torchserve.default.example.com http://localhost:8080/v1/models/mnist:predict
hey -n 10000 -c 4 -q 1 -D ./torch_mnist_digit7.json -m POST -host torchserve.default.example.com http://localhost:8080/v1/models/mnist:predict