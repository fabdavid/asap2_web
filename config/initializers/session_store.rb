# Be sure to restart your server when you modify this file.

#Rails.application.config.session_store :cookie_store,
 #                                      key: '_asap2_session'
Rails.application.config.session_store :active_record_store, key: '_asap2_session', expire_after: 30.minutes, secure: false#, 
#                                        same_site: :lax
#same_site: 'None'
