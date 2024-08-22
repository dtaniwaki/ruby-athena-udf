# AthenaUDF

Ruby-version Athena User Defined Function (UDF).

This gem is highly inspired by [the Python-version Athena UDF](https://github.com/dmarkey/python-athena-udf).

See [an official example implementation](https://github.com/awslabs/aws-athena-query-federation/blob/fc2e4e9cdcb71ec7f7c7d44cbda7f56c5835811e/athena-federation-sdk/src/main/java/com/amazonaws/athena/connector/lambda/handlers/UserDefinedFunctionHandler.java) for more detail of a lambda function for Athena UDF.

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add athena-udf
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install athena-udf
```

## Usage

Just make a subclass of `AthenaUDF::BaseUDF` and implement a concrete function logic.

```rb
require "athena_udf"

class SimpleVarcharUDF < AthenaUDF::BaseUDF
  def self.handle_athena_record(_input_schema, _output_schema, record)
    [record[0].downcase]
  end
end
```

Then, it can be called as `SimpleVarcharUDF.lambda_handler` in your lambda function for Athena UDF workloads.

After pushing an image to Amazon ECR, you can call the function like the following SQL.

```sql
USING EXTERNAL FUNCTION my_udf(col1 varchar) RETURNS varchar LAMBDA 'athena-udf-simple-varchar'

SELECT my_udf('FooBar');
```

See [the official document](https://docs.aws.amazon.com/athena/latest/ug/querying-udf.html) for the UDF usage.

## Development

To contribute to this library, first checkout the code. Then, install the dependent gems.

```sh
$ bundle install
```

To run the tests:

```sh
$ bundle exec rspec
```

## Deployment

You can try the example with the following steps.

First, push a container image to Amazon ECR:

```sh
$ docker build --platform=linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/athena-udf-test -f Dockerfile.example .
$ docker push <ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/athena-udf-test
```

Then, create a lambda function with the CLI:

```sh
$ aws iam create-role --role-name athena-udf-simple-varchar --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
$ aws iam attach-role-policy --role-name athena-udf-simple-varchar --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
$ aws lambda create-function --function-name athena-udf-simple-varchar --package-type Image --role arn:aws:iam::<ACCOUNT_ID>:role/athena-udf-simple-varchar --code ImageUri=<ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/athena-udf-test:latest --publish
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dtaniwaki/ruby-athena-udf.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

