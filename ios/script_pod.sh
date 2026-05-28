post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Bloque para forzar la firma correcta en todos los frameworks de los Pods
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = '-'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
    end
  end
end