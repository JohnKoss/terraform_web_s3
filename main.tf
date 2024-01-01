/////////////////////////////////////////////////////////////////////////////////////////
/////////// The HTML pages stored in S3 /////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

variable "name" {
  type        = string
  description = "The name of the folder"
}
variable "bucket_name" {
  type        = string
  description = "The name of the bucket to hold the files"
}
variable "path_html_src" {
  type        = string
  description = "The location of the files to compile"
  default     = "../src"
}
variable "path_html_dist" {
  type        = string
  description = "The location of the compiled files"
  default     = "../dist"
}
variable "path_hcl" {
  type        = string
  description = "The location of the lab's configuration files"
  default     = "../hcl"
}
variable "path_scoring" {
  type        = string
  description = "The location of the lab's scoresheet and related files (if any)"
  default     = "../scoring"
}
variable "path_objects" {
  type        = string
  description = "The location of any object files the lab may require the learner to use."
  default     = "../objects"
}

/////////////
locals {
  sha1 = sha1(join("", [for f in fileset("${path.root}/${var.path_html_src}", "**") : filesha1("${path.root}/${var.path_html_src}/${f}")]))
  sha2 = sha1(join("", [for f in fileset("${path.root}/${var.path_html_dist}", "**") : filesha1("${path.root}/${var.path_html_dist}/${f}")]))
}

resource "terraform_data" "website" {
  # Defines when the provisioner should be executed
  triggers_replace = [local.sha1, local.sha2]

  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = path.root
  }

  input = "${local.sha1}${local.sha2}}"
}

// Upload the HTML, img and javascript files.
resource "aws_s3_object" "website" {
  for_each = fileset("${path.root}/${var.path_html_dist}", "**")

  bucket = var.bucket_name
  key    = "${var.name}/html/${each.value}"
  source = "${path.root}/${var.path_html_dist}/${each.value}"

  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1))

  lifecycle {
    replace_triggered_by = [
      terraform_data.website.output
    ]
  }
}

// https://barneyparker.com/posts/uploading-file-trees-to-s3-with-terraform/
locals {
  mime_types = {
    "css"  = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "png"  = "image/png"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
  }
}

##########

resource "aws_s3_object" "hcl" {
  for_each = fileset("${var.path_hcl}", "**")

  bucket = var.bucket_name
  key    = "${var.name}/hcl/${each.value}"
  source = "${var.path_hcl}/${each.value}"
}

resource "aws_s3_object" "scoring" {
  for_each = fileset("${var.path_scoring}", "**")

  bucket = var.bucket_name
  key    = "${var.name}/scoring/${each.value}"
  source = "${var.path_scoring}/${each.value}"
}

resource "aws_s3_object" "objects" {
  for_each = fileset("${var.path_objects}", "**")

  bucket = var.bucket_name
  key    = "${var.name}/objects/${each.value}"
  source = "${var.path_objects}/${each.value}"
}
