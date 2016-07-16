ref = new Firebase "https://question-everything.firebaseio.com"
ref.authAnonymously (err, data) ->

  renderQuestion = (link = "head", previous = false) ->
    getNextQ = (finish) ->
      if link
        ref.child(link).once 'value', (doc) ->
          finish doc
      else
        finish null


    getNextQ (doc) ->
      $questions = $('body > .questions')
      $questions.empty()
      if doc isnt null
        doc.forEach (child_doc) ->
          {question, answer_1, answer_2} = child_doc?.val() or {}
          return false unless question and answer_1 and answer_2
          $question = $questions.append teacup.render ->
            div '.question', 'data-key': child_doc.key(), ->
              div '.question-header', -> question
              div '.answers', ->
                div '.answer_1', 'data-next': answer_1.next, -> answer_1.text
                div '.answer_2', 'data-next': answer_2.next, -> answer_2.text
          $question.find('.answers > div').on 'click', (e) ->
            $el = $ e.currentTarget
            next = $el.data('next')
            key = $el.closest('.question').data 'key'
            renderQuestion next, "#{link}/#{key}/#{$el.attr('class')}"
          return false

      $question = $questions.append teacup.render ->
        div '.question', ->
          form ->
            input '.question-header', placeholder: "Add your own question to keep it going!", required: true
            div '.answers', ->
              input '.answer_1', placeholder: 'Put answer one here', required: true
              input '.answer_2', placeholder: 'Put answer two here', required: true
            input type:'submit', value: 'submit'

      $question.find('form').on 'submit', (e) ->
        if not link
          link = "leaf/#{ref.child('leaf').push().key()}"
        $el = $ e.currentTarget
        new_q = ref.child(link).push()
        new_q.set {
          answer_1:
            text: $el.find('input.answer_1').val()
          answer_2:
            text: $el.find('input.answer_2').val()
          question: $el.find('input.question-header').val()
        }, ->
          question_location = "#{link}/#{new_q.key()}"
          ref.child("#{previous}/next").set link, ->
            renderQuestion link, previous
        return false


  renderQuestion()




