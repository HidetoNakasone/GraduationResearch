
require 'bundler'
Bundler.require

require 'net/http'

GOOGLE_API_KEY = ENV['GOOGLE_API_KEY']
GOOGLE_SEARCH_CX = ENV['GOOGLE_SEARCH_CX']

# 開発環境のみ実行 (Heroku環境だと実行しない)
if development?
  require 'sinatra/reloader'
  require 'dotenv'
  Dotenv.load ".env"

  def client
    @client ||= PG::connect(
      dbname: 'graduation_research',
    )
  end
else
  def client
    uri = URI.parse(ENV['DATABASE_URL'])
    @client ||= PG::connect(
      host: uri.hostname,
      dbname: uri.path[1..-1],
      user: uri.user,
      port: uri.port,
      password: uri.password
    )
  end
end

get '/' do
  datas = client.exec_params("select * from words;")
  puts "データ数： #{datas.to_a}"
  @datas = datas
  erb :index
end

get '/my_ajax' do
  # 今回は2つま同時までしか対応しない。
  get_arr = params[:marker_list].split(',')
  marker_list = []

  get_arr.each do |i|
    res = client.exec_params("select * from words where id = $1", [i.to_i])
    marker_list.append(res.first["word"].to_s)
  end

  marker_list.to_json
end

get '/my_ajax_2' do
  get_arr = params[:marker_list].split(',')
  marker_list = []

  get_arr.each do |i|
    res = client.exec_params("select * from words where id = $1", [i.to_i])
    marker_list.append(res.first["word"].to_s)
  end

  search_text = marker_list.join(' ')
  # p search_text

  res = client.exec_params('select url_text from urls where word_text = $1', [search_text]).first

  res_link = ""

  if res.to_a.length != 0
    p 'DB検索結果： 成功。既存のURLを返却します。'
    res_link = res['url_text']
  else
    p 'DB検索結果： 一致無し'

    # Google CustomSearch APIへのリクエスト
    results = GoogleCustomSearchApi.search(search_text, {"searchType" => "image"})
    results.items.each do |item|
      puts item.title, item.link
      if item.link.include?('.jpg') or item.link.include?('.png')
        res_link = item.link
        break
      end
    end

    p "============================"
    p results
    p "============================"

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

    client.exec_params("insert into urls(word_text, url_text) values($1, $2);", [search_text, res_link])
  end

  res_link.to_json
end
