
require 'sinatra'
require 'google_custom_search_api'
require 'net/http'
require 'json'

# 開発環境のみ実行 (Heroku環境だと実行しない)
if development?
  require 'sinatra/reloader'
  require 'dotenv'
  Dotenv.load ".env"
end

GOOGLE_API_KEY = ENV['GOOGLE_API_KEY']
GOOGLE_SEARCH_CX = ENV['GOOGLE_SEARCH_CX']

json_data = open('./data.json') { |io| JSON.load(io) }

get '/' do
  puts "データ数： #{json_data}"
  @json_data = json_data
  erb :index
end

get '/my_ajax' do
  # 今回は2つま同時までしか対応しない。
  get_arr = params[:marker_list].split(',')
  marker_list = []

  get_arr.each { |i| marker_list.append(json_data[i]) }
  marker_list.to_json
end

get '/my_ajax_2' do
  get_arr = params[:marker_list].split(',')
  marker_list = []
  get_arr.each { |i| marker_list.append(json_data[i]) }

  search_text = marker_list.join(' ')
  p search_text

  res_link = ""

  # Google CustomSearch APIへのリクエスト
  results = GoogleCustomSearchApi.search(search_text, {"searchType" => "image"})
  results.items.each do |item|
    puts item.title, item.link
    if item.link.include?('.jpg') or item.link.include?('.png')
      res_link = item.link
      break
    end
  end

  # Google CustomSearch API の上限クエリ制限によってerrorレスポンス(itemsが空のレスポンス)が届いたら、Bing CustomSearch API へリクエストを送る
  if results.items.length == 0
    # Bing CustomSearch APIへのリクエスト
    p "Bingへリクエスト送信します。"
    uri = URI('https://api.cognitive.microsoft.com/bing/v7.0/search')
    uri.query = URI.encode_www_form({
      'q' => search_text,
      'count' => '1',
      'offset' => '0',
      'mkt' => 'ja',
      'safesearch' => 'Moderate'
    })

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Ocp-Apim-Subscription-Key'] = ENV['BING_SEARCH_API_KEY']
    request.body = ""
    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
    end

    res_conv = JSON(response.body)['images']
    res_link = res_conv['value'].first['contentUrl'] if res_conv != nil
  end

  res_link.to_json
end
