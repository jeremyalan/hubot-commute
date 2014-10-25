_ = require('underscore')

module.exports = (robot) ->
  robot.respond /get me home/i, (msg) ->
    user = msg.envelope.user

    origin_location = robot.brain.get('locations::origin')

    if not origin_location
      msg.send "Sorry, the origin address has not been set. (@hubot set location origin <address>)'"
      return

    user_location = robot.brain.get("locations:#{ user.id }")
    
    if not user_location
      msg.reply 'Where do you live? (@hubot set location home <address>)'
      return

    robot.http("https://maps.googleapis.com/maps/api/directions/json?origin=#{ origin_location }&destination=#{ user_location }")
      .get() (err, res, body) ->
        try
          data = JSON.parse(body)

          if err or res.statusCode isnt 200
            msg.send "Sorry, the request to Google Maps was unsuccessful, please try again."
            return

          route_infos = _.map data.routes, (route) -> 
            "#{ route.summary }: #{ route.legs[0].duration.text }"

          msg.send route_infos.join('\n')
        catch e
          console.log e
          msg.send 'Oops, an unexpected error occurred, please try again.'

  robot.respond /show location origin/i, (msg) ->
    origin_location = robot.brain.get('locations::origin')
    msg.send "Origin location is currently set to: #{ origin_location }"

  robot.respond /set location origin (.*)/i, (msg) ->
    origin_location = msg.match[1]
    robot.brain.set 'locations::origin', origin_location

    msg.send "Origin location has been set to #{ origin_location }"

  robot.respond /show location home/i, (msg) ->
    user = msg.envelope.user
    user_location = robot.brain.get("locations:#{ user.id }")
    msg.send "Your location is currently set to: #{ user_location }"

  robot.respond /set location home (.*)/i, (msg) ->
    user_location = msg.match[1]
    robot.brain.set "locations:#{ msg.envelope.user.id }", user_location

    msg.reply "Your home location has been set to #{ user_location }"