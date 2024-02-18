resource "aws_cloudwatch_event_rule" "failed_glue_jobs_rule" {
  name           = "glue -ob-failure-rule"
  description    = "publish glue state events"
  event_bus_name = "default"
  event_pattern = jsonencode({
    source      = ["aws.glue"],
    detail-type = ["Glue Job State Change"],
    detail = {
      state = ["FAILED", "ERROR"]
    }
  })
}

resource "aws_cloudwatch_log_group" "glue_jobs_log" {
  name = "/aws.events/my-glue-jobs-failure"
}

resource "aws_cloudwatch_event_target" "eventbridge_target" {
  rule = aws_cloudwatch_event_rule.failed_glue_jobs_rule.name
  arn  = aws_cloudwatch_log_group.glue_jobs_log.arn
}

resource "aws_iam_role" "eventbridge_listener_role" {
  name = "eventbridge-log-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "events.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eventbridge_cloudwatch_policy" {
  name = "eventbridge-log-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource" : aws_cloudwatch_log_group.glue_jobs_log.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_cloudwatch_attachment" {
  policy_arn = aws_iam_policy.eventbridge_cloudwatch_policy.arn
  role       = aws_iam_role.eventbridge_listener_role.name
}

resource "aws_cloudwatch_log_metric_filter" "failed_glue_jobs_metric_filter" {
  name           = "my-job-failure-filter-group"
  pattern        = "{ ($.detail.state = \"FAILED\") || ($.detail.state = \"ERROR\") }"
  log_group_name = aws_cloudwatch_log_group.glue_jobs_log.name

  metric_transformation {
    name      = "numFailedJobsCount"
    namespace = "aws.custom-namespace"
    value     = "1"
    unit      = "Count"
    dimensions = {
      jobName  = "$.detail.jobName"
      jobRunId = "$.detail.jobRunId"
      message  = "$.detail.message"
    }
  }
}