msnry = null
ref = new Firebase "https://question-everything.firebaseio.com"


ref.authAnonymously (err, data) ->

  renderHeader = ->
    nav = {
      '/pages/faq.html': 'faq'
      '/pages/explanation.html': 'what is this'
      '/pages/graph.html': 'view graph'
      '/main.html': 'home'
    }
    subjects = {
      'serious': 'Serious'
      'fun': 'Fun'
      'stories': 'Stories'
      'testing': 'testing'
    }
    times  = {
      'past-hour': 'past hour'
      'past-month': 'past 24 hours'
      'past-year': 'past year'
      'all-time': 'all time'
    }

    $header = $('body > .container > .header')
    $header.html teacup.render ->
      div '.nav', ->
        for key, val of nav
          a '.nav-item', href: key, -> val
      div '.subjects', ->
        for key, val of subjects
          div '.subject', 'data-subject': key, -> val
      select '.time-slot', ->
        for key, val of times
          option value: key, -> val



  renderQuestion = (link = "head", previous = false) ->

    getNextQ = (finish) ->
      if link
        ref.child(link).orderByChild("vote_inverse").once 'value', (doc) ->
          console.log doc.val()
          finish doc
      else
        finish null

    $('body .questions-container').html teacup.render ->
      div '.questions'

    $questions = $('body .questions')
    $(window).off 'resize', ->
    $(window).on 'resize', ->
      width = Math.floor $(window).width() / 340
      $('.questions-container').css 'max-width', "#{width * 340}px"

    getNextQ (doc) ->
      if doc isnt null
        doc.forEach (child_doc) ->
          {question, answer_1, answer_2, vote} = child_doc?.val() or {}
          return false unless question and answer_1 and answer_2
          item = localStorage.getItem(child_doc.key()) or {}
          $question = $ teacup.render ->
            div '.question', 'data-key': child_doc.key(), ->
              div '.voting', ->
                div 'data-arrow':'up'
                div ".vote", ->
                div 'data-arrow':'down'
              div '.question-header', -> question
              div '.answers', ->
                div '.answer_1', 'data-next': answer_1.next, -> answer_1.text
                div '.answer_2', 'data-next': answer_2.next, -> answer_2.text
          $questions.append $question
          do ($question) ->
            $question.find('[data-arrow]').on 'click', (e) ->
              $el = $ e.currentTarget
              debugger;
              incriment = if $el.data('arrow') is 'up' then 1 else -1
              item = JSON.parse localStorage.getItem(child_doc.key()) or '{}'
              modified_incriment = incriment
              if item.vote is incriment
                modified_incriment = incriment * -1
                incriment = 0
              else if item.vote is incriment * -1
                modified_incriment = incriment * 2

              item.vote = incriment

              # stupid yes but firebase doesn't support reverse order
              item.vote_inverse = incriment * -1
              localStorage.setItem child_doc.key(), JSON.stringify item

              ref.child("#{link}/#{child_doc.key()}/vote").once 'value', (current_vote_doc) ->
                currentVote = current_vote_doc?.val() or 0
                new_val = currentVote + modified_incriment
                ref.child("#{link}/#{child_doc.key()}/vote").set new_val
                ref.child("#{link}/#{child_doc.key()}/vote_inverse").set new_val * -1

            ref.child("#{link}/#{child_doc.key()}/vote").on 'value', (vote_doc) ->
              new_vote = vote_doc?.val() or 0
              $vote = $question.find('.vote')
              $vote.html "#{new_vote}"
              $vote.toggleClass 'bad', new_vote < 0
              $vote.toggleClass 'good', new_vote > 5

              item = JSON.parse localStorage.getItem(child_doc.key()) or '{}'
              debugger;
              local_vote = 'none'
              if item.vote > 0
                local_vote = 'up'
              else if item.vote < 0
                local_vote = 'down'
              $question.attr 'data-vote', local_vote


            $question.find('.answers > div').on 'click', (e) ->
              $el = $ e.currentTarget
              next = $el.data('next')
              key = $el.closest('.question').data 'key'
              key_previous = "#{link}/#{key}/#{$el.attr('class')}"
              ref.child("#{key_previous}/count").transaction (currentCount) ->
                currentCount ?= 0
                return currentCount + 1
              renderQuestion next, key_previous
            return false

      $new_question = $ teacup.render ->
        div '.question', ->
          form ->
            div '.text-area-container', ->
              textarea '.question-header', maxlength: 250, placeholder: "Add your own question", required: true
              div '.resizer question-header', -> 'A'
              div '.characters', -> ''
            div '.answers', ->
              div '.text-area-container', ->
                textarea '.answer_1',maxlength: 140, placeholder: 'Put answer one here', required: true
                div '.resizer answer_1', -> 'A'
                div '.characters', -> ''
              div '.text-area-container', ->
                textarea '.answer_2', maxlength: 140, placeholder: 'Put answer two here', required: true
                div '.resizer answer_2', -> 'A'
                div '.characters', -> ''
            input type:'submit', value: 'submit'
      do ($new_question) ->
        $questions.append $new_question

        $new_question.find('textarea').on 'input', (e) ->
          $el = $ e.currentTarget
          $el.next().html "#{$el.val() or 'A'}\n\n"
          maxlength = $el.attr 'maxlength'
          $el.siblings('.characters').html maxlength - $el.val().length

        $new_question.find('form').on 'submit', (e) ->
          if not link
            link = "leaf/#{ref.child('leaf').push().key()}"
          $el = $ e.currentTarget
          new_q = ref.child(link).push()
          new_q.set {
            answer_1:
              text: $el.find('textarea.answer_1').val()
            answer_2:
              text: $el.find('textarea.answer_2').val()
            question: $el.find('textarea.question-header').val()
          }, ->
            question_location = "#{link}/#{new_q.key()}"
            ref.child("#{previous}/next").set link, ->
              renderQuestion link, previous
          return false

      $('.questions').masonry {
        itemSelector: '.question'
        layoutPriorities:
          upperPosition: 1
          shelfOrder: 1
      }
      msnry = $('.questions').data 'masonry'
      $(window).trigger('resize')


  renderHeader()
  renderQuestion()




