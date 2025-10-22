locals {
  rendered_frontend_yaml_data = templatefile("${path.module}/k8s/ai-agent-frontend.yaml.tpl",{
    docker_image      = var.ai_agent_frontend_docker_image
    chatbot_api_url   = "${data.external.ai_agent_url.result.external_ip}:8002/chat"
  })

  depends_on = [kubectl_manifest.ai-agent-service]
}

resource "local_file" "frontend_app_file_spec" {
  content  = local.rendered_frontend_yaml_data
  filename = "${path.module}/k8s/ai-agent-frontend.yaml"
}

resource "kubectl_manifest" "ai-agent-frontend-app" {
  yaml_body = local_file.frontend_app_file_spec.content
  depends_on = [local_file.frontend_app_file_spec]
}

resource "kubectl_manifest" "ai-agent-frontend-service" {
  yaml_body = file("${path.module}/k8s/ai-agent-frontend-service.yaml")
  depends_on = [kubectl_manifest.ai-agent-frontend-app]
}
