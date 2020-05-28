require 'sinatra'
require 'httparty'
require 'pdf-reader'
require 'sinatra/json'

DIVISA_URL = 'https://cdn.bancentral.gov.do/documents/estadisticas/mercado-cambiario/documents/TMC4001.pdf?v=1590627744657?v=1590627744662'

get '/api/' do
  file_path = "public/divisas_#{Date.today.to_s}"

  unless File.exists?(file_path)
    File.open(file_path, 'w') do |file|
      file.binmode
      HTTParty.get(DIVISA_URL, stream_body: true) do |fragmet|
        file.write(fragmet)
      end
    end
  end

  divisas = []
  if File.exists?(file_path)
    reader = PDF::Reader.new(file_path)

    reader.pages.each do |page|
      lines = page.text.scan(/^.+/)
      lines.each do |line|
        matches = line.match(/\A\s+(\w+)\s+(\w+)\s+(\w+)?\s+(\d+\.\d+)/)
        if matches
          divisas.push({
            code: matches[1],
            nombre: [matches[2], matches[3]].join(' '),
            rate: matches[4]
          })
        end
      end
    end
  end

  json divisas
end
