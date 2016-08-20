class KmflowController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:flow_fracaso, :flow_exito, :flow_confirma]
  before_action :verificar_respuesta, only: [:flow_exito, :flow_fracaso, :flow_confirma]

  ## La página de éxito te sirve para poner agregar los datos a tu base de datos
  ## tienes la variable @flow con todos los datos de la orden

  #### Variables de retorno
  ## kpf_orden : Número de la orden realizada (corresponde a tu ID)
  ## kpf_concepto : Descripción del producto pagado
  ## kpf_pagador : Email del comprador
  ## kpf_flow_order : Número de la orden interna de Flow
  ## s : Datos encriptados con tu llave

  def flow_exito

  end

  def flow_fracaso

  end





  #### Métodos de confirmación, se recomienda no cambiar
  ## flow_confirma : corresponde al estatus de la orden por parte de Webpay para validar
  ## verificar_respuesta : Confirma que antes que se ejecute cualquier página, existan los parámetros desde Flow
  protected
  def flow_confirma
    logger.info "confirmando #################"
    logger.info params[:response]
    status = Kmflow::Pagos::read_confirm(params[:response])
    logger.info "resultado de  read_confirm #################"
    logger.info status
    logger.info "comienza if  de flow_confirma #################"
    if status['status'] == 'EXITO'
      Kmflow::Pagos::build_response(true)
    else
      Kmflow::Pagos::build_response(false)
    end
  end
  private
  def verificar_respuesta

    logger.info "Verificando respuesta #################"
    logger.info params[:response]
    resp = Kmflow::Pagos::verificar_respuesta(params[:response])
    logger.info "resultado de verificar_respuesta #################"
    logger.info resp
    logger.info "comienza if de verificar_respuesta #################"
    if resp['response']
      @flow = resp['order']
    else
      redirect_to flow_fracaso_path
    end
  #rescue
   # redirect_to flow_fracaso_path
  end
end
