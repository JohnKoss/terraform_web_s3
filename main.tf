/////////////////////////////////////////////////////////////////////////////////////////
/////////// The HTML pages stored in S3 /////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

variable "name" {
  type        = string
  description = "The name of the folder"
}
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

/////////////
locals {
  sha1 = sha1(join("", [for f in fileset("${path.root}/${var.src_path}", "**") : filesha1("${path.root}/${var.src_path}/${f}")]))
  sha2 = sha1(join("", [for f in fileset("${path.root}/${var.dist_path}", "**") : filesha1("${path.root}/${var.dist_path}/${f}")]))
}

resource "terraform_data" "website" {
  # Defines when the provisioner should be executed
  triggers_replace = [local.sha1, local.sha2]

  provisioner "local-exec" {
      command = "npm run build"
      working_dir = path.root
  }

  input = "${local.sha1}${local.sha2}}"
}

// Upload the HTML, img and javascript files.
resource "aws_s3_object" "website" {
  for_each = fileset("${path.root}/${var.dist_path}", "**")

  bucket = var.bucket_name
  key    = "${var.name}/html/${each.value}"
  source = "${path.root}/${var.dist_path}/${each.value}"

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
