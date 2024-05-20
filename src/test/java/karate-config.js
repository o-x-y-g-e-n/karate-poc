function fn() {
  var env = karate.env; // get system property 'karate.env'
  karate.log('karate.env system property was:', env);
  if (!env) {
    env = 'dev';
  }
  var config = {
    baseUrl: 'https://dummyjson.com',
  };

  // assuming we have 2 env
  if(env.equals("dev")){
    config.baseUrl = "https://dummyjson.com"
  }else if(env.equals("stage")){
    config.baseUrl = "https://dummyjson.com"
  }
  else {
      karate.log('Invalid environment:', env);
      // Optional: throw an error to fail the initialization
      throw new Error('Invalid environment parameter: ' + env);
      // Or alternatively, set a default baseUrl or handle it accordingly
      // config.baseUrl = "https://dummyjson.com";
    }
  return config;
}
