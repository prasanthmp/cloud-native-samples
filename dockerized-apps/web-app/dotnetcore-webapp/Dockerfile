# Use the official .NET SDK image for build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy the rest of the app
COPY . ./
RUN dotnet publish -c Release -o out

# Use a runtime-only image for running the app
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/out ./

# Expose port (optional, but good practice)
EXPOSE 80

# Entry point
ENTRYPOINT ["dotnet", "DotNetCoreWebapp.dll"]
