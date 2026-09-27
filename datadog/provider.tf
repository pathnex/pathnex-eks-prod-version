terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_ssm_parameter" "datadog_api_key" {
  name            = "DD-api"
  with_decryption = true
}

data "aws_ssm_parameter" "datadog_app_key" {
  name            = "DD-app"
  with_decryption = true
}

provider "datadog" {
  api_key = data.aws_ssm_parameter.datadog_api_key.value
  app_key = data.aws_ssm_parameter.datadog_app_key.value
}

