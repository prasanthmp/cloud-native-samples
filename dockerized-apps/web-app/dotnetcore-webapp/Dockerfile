# ------------------------
# Build Stage
# ------------------------
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy the project file and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy the rest of the source code
COPY . .

# Publish the app to the /app/publish directory
RUN dotnet publish -c Release -o /app/publish

# ------------------------
# Runtime Stage
# ------------------------
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Copy published app from build stage
COPY --from=build /app/publish .

# Expose the default port
EXPOSE 8080

# Start the app
ENTRYPOINT ["dotnet", "dotnetcore-webapp.dll"]
