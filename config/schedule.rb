every 5.minutes do
  runner "ClientsSync.run"
  runner "PlacesUpdater.perform"
end
