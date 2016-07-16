ref = new Firebase "https://question-everything.firebaseio.com"
ref.authAnonymously (err, data) ->

  renderQuestion = (link = "head/0", previous = false) ->
    async.waterfall []

    getNextQ = (finish) ->
      if link
        ref.child(link).once 'value', (doc) ->
          finish doc
      else
        finish null


    getNextQ (doc) ->
      {question, answer_1, answer_2} = doc?.val() or {}
      $question = $('body > .question')
      if question and answer_1 and answer_2
        $question .html teacup.render ->
          div '.question', -> question
          div '.answers', ->
            div '.answer_1', 'data-next': answer_1.next, -> answer_1.text
            div '.answer_2', 'data-next': answer_2.next, -> answer_2.text
        $question.find('.answers > div').on 'click', (e) ->
          $el = $ e.currentTarget
          next = $el.data('next')
          renderQuestion next, "#{link}/#{$el.attr('class')}"
      else
        $question.html teacup.render ->
          form ->
            input '.question', placeholder: "Add your own question to keep it going!", required: true
            div '.answers', ->
              input '.answer_1', placeholder: 'Put answer one here', required: true
              input '.answer_2', placeholder: 'Put answer two here', required: true
            input type:'submit', value: 'submit'
        console.log "#{previous}/next"
        $question.find('form').on 'submit', (e) ->
          $el = $ e.currentTarget
          $el.find('input').each (index, value) ->
          new_q = ref.child('leaf').push()
          new_q.set {
            answer_1:
              text: $el.find('input.answer_1').val()
            answer_2:
              text: $el.find('input.answer_2').val()
            question: $el.find('input.question').val()
          }, ->
            question_location = "leaf/#{new_q.key()}"
            ref.child("#{previous}/next").set question_location, ->
              renderQuestion question_location
          return false


  renderQuestion()




