using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Net;
using System.Net.Sockets;

namespace DotnetCoreWebapp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;

    public string? ServerIP { get; set; }
    public string? ServerName { get; set; }

    public void OnGet()
    {
        try
        {
            ServerName = Dns.GetHostName();

            var host = Dns.GetHostEntry(ServerName);
            _logger.LogInformation("Retrieved server name: {ServerName}", ServerName);

            foreach (var ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork)
                {
                    ServerIP = ip.ToString();

                    _logger.LogInformation("Retrieved server IP address: {ServerIP}", ServerIP);
                    break;
                }
            }

            ServerIP ??= "Unavailable";
            if (ServerIP == "Unavailable")
            {
                _logger.LogWarning("No IPv4 address found for the server.");
            }
        }
        catch (Exception ex)
        {
            ServerName = "Unavailable";
            ServerIP = "Unavailable";
            _logger.LogError(ex, "Failed to retrieve server information.");
        }
    }

    public IndexModel(ILogger<IndexModel> logger)
    {
        _logger = logger;
    }
}
