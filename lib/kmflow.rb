require "kmflow/engine"
module Kmflow
  require 'openssl'
  require 'base64'
  class Pagos
    def self.nuevo(data)
      pedido = "c="+CGI::escape(cfg['email_tienda'].to_s)+"&ti="+cfg['tipo_pago'].to_s+"&oc="+CGI::escape(data[:orden].to_s)+"&mp="+cfg['medio_pago'].to_s+
      "&o="+CGI::escape(data[:concepto].to_s)+"&m="+CGI::escape(data[:monto].to_s)+"&ue="+CGI::escape((cfg['url']+cfg['url_exito']).to_s)+"&uf="+CGI::escape((cfg['url']+cfg['url_fracaso']).to_s)+
      "&uc="+CGI::escape((cfg['url']+cfg['url_confirmacion']).to_s)+"&e="+CGI::escape(data[:email].to_s)
      enc = flow_sign(pedido)
      flowHash = pedido + '&s=' +  enc
      log.info "Boton creado correctamente"
      if data[:boton]
        btntxt = data[:boton]
      else
        if cfg['medio_pago'] == 1
          btntxt = 'Pagar con Webpay'
        elsif cfg['medio_pago'] == 2
          btntxt = 'Pagar con Servipag'
        else
          btntxt = 'Pagar con Flow'
        end
      end
      form = "<form method=\"post\" action=\"#{cfg['url_form']}\" class=\"#{data[:class]? data[:class] : 'flow-form'}\">
      <input type=\"hidden\" name=\"parameters\" value=\"#{flowHash}\"/><button type=\"submit\">#{btntxt}</button></form>"
      data[:return] == 'hash' ? flowHash : form.html_safe
    end

    def self.verificar_respuesta(flowParams)
      require "rack"
      log.info "metodo verificar_respuesta"
      log.info "procesando order = Rack::Utils.parse_nested_query(flowParams)"
      order = Rack::Utils.parse_nested_query(flowParams)
      #log.info order
      log.info "sacando la llave del hash"
      noKey = flowParams.split('&s=').first
      #log.info noKey
      log.info "verificando la llave"
      kDecode = Base64.decode64(order['s'])
      #log.info kDecode
      log.info "verificando la firma"
      ver = public_key.verify OpenSSL::Digest::SHA1.new, kDecode, noKey
      #log.info ver
      log.info 'Firma pública verificada correctamente' if ver
      { 'response' => ver, 'order' => order }
    end

    def self.loger(m)
      log.info m.to_s
    end

    private
    def self.cfg
      YAML.load_file("#{::Rails.root.to_s}/config/kmflow.yml")[Rails.env]
    end

    def self.build_response(result_bool)
      log.info "en build_response #########################"
      r = result_bool ? 'ACEPTADO' : 'RECHAZADO'
      data = ['status' => r, 'c' => cfg['email_tienda']]
      log.info "status y email: #{data}"
      log.info "Status: #{r}"
      q = URI.encode_www_form(data)
      log.info "datos importantes #########################"
      log.info q
      log.info "firmando #########################"
      sign = flow_sign(q)
      log.info sign
      #q+'&s='+sign.html_content
      firma = q+'&s='+sign
      log.info "firma realizada: #{firma}"
      return firma
    end

    def self.flow_sign(data)
      prvkey = private_key()
      enc = prvkey.sign(OpenSSL::Digest::SHA1.new, data)
      log.error 'No se pudo firmar con la llave privada' if !enc
      Base64.encode64(enc)
    end

    def self.read_confirm(r)
      log.info "en read_confirm ##################"
      order = Rack::Utils.parse_nested_query(r)
      log.info order
      log.info order['status']
      {'status' => order['status']}
      log.error 'invalid response status' if !order
      log.error 'Mensaje no tiene firma' if !order['s']
      log.error 'Firma invalida' if !verificar_respuesta(r)
      log.error 'No hay número de orden' if !order['kpf_orden']
      return order
    rescue
      render text: 'FRACASO'
    end

    def self.private_key
      OpenSSL::PKey::RSA.new File.read cfg['key_privada']
    end

    def self.public_key
      OpenSSL::PKey::RSA.new File.read cfg['key_publica']
    end

    def self.log
      @@log ||= Logger.new("#{Rails.root}/log/kmflow.log")
    end

  end
end
