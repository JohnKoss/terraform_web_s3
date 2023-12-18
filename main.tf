/////////////////////////////////////////////////////////////////////////////////////////
/////////// The HTML pages stored in S3 /////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

variable "name" {
  type        = string
  description = "The name of the folder"
}
# variable "path" {
#   type        = string
#   description = "The path of the folder"
#   default = "labs"
# }
variable "src_path" {
  type        = string
  description = "The location of the files to compile"
  default = "src"
}
variable "dist_path" {
  type        = string
  description = "The location of the compiled files"
  default = "dist"
}
variable "bucket_name" {
  type        = string
  description = "The name of the bucket to hold the files"
}

///
# locals {
#   name           = "lti13/course_navigation"
#   src_path       = "src"
#   dist_directory = "dist"
#   bucket_name    = "lti13.clearbyte.io"
# }
/////////////
locals {
  sha1 = sha1(join("", [for f in fileset("${path.module}/${var.src_path}", "**") : filesha1("${path.module}/${var.src_path}/${f}")]))
}

resource "terraform_data" "website" {
  # Defines when the provisioner should be executed
  triggers_replace = [local.sha1]

  provisioner "local-exec" {
      command = "npm run build"
      working_dir = path.module
  }

  input = "${local.sha1}"
}

// Upload the HTML, img and javascript files.
resource "aws_s3_object" "website" {
  for_each = fileset("${path.module}/dist", "**")

  bucket = var.bucket_name
  key    = "${var.name}/${each.value}"
  source = "${path.module}/${var.dist_path}/${each.value}"

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
# resource "null_resource" "build" {
#   triggers = {
#     sha1 = sha1(join("", [for f in fileset("${var.root_path}/${var.name}/${var.src_path}", "**") : filesha1("${var.root_path}/${var.name}/${var.src_path}/${f}")]))
#   }

#   provisioner "local-exec" {
#     command     = "npm run ${var.build_cmd}"
#     working_dir = "${var.root_path}/${var.name}"
#   }

#   provisioner "local-exec" {
#     command     = "aws s3 sync ${var.root_path}/${var.name}/${var.dist_directory} s3://${var.bucket_name}/${var.name}"
#     working_dir = path.module
#   }

# }
