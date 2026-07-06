resource "aws_accessanalyzer_analyzer" "unused_access" {
  analyzer_name = "unused-access-analyzer"
  type          = "ACCOUNT_UNUSED_ACCESS"

  configuration {
    unused_access {
      unused_access_age = var.unused_access_age
    }
  }

  tags = local.common_tags
}
