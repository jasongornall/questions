msnry = null
ref = new Firebase "https://question-everything.firebaseio.com"

NAV = {
  'home': 'home'
  'faq': 'faq'
  'exp': 'what is this'
  'graph': 'view graph'
}
SUBJECTS = {
  'fun': 'Fun'
  'serious': 'Serious'
  'stories': 'Stories'
  'test': 'testing'
}
TIMES  = {
  'hour': 'past hour'
  'day': 'past 24 hours'
  'year': 'past year'
  'all': 'all time'
}


ref.authAnonymously (err, data) ->

  renderHeader = ->

    $header = $('body > .container > .header')
    nav_selected = $.url('?n') or 'home'
    subject_selected = $.url('?s') or 'fun'
    times_selected = $.url('?t') or 'all'
    updateUrl = (json) ->
      variables =  $.url('?') or {}
      variables[key] = val for key, val of json
      params = ("#{k}=#{encodeURIComponent v}" for k, v of variables).join '&'
      history.pushState(null, null, "?#{params}");
    $header.html teacup.render ->
      div '.nav', ->
        for key, val of NAV
          div '.nav-item', 'data': {
            'nav': key
            'selected': "#{key is nav_selected}"
          }, -> val
      div '.subjects', ->
        for key, val of SUBJECTS
          div '.subject', 'data': {
            subject: key
            selected: "#{key is subject_selected}"
          }, -> val
      select '.time-slot', ->
        for key, val of TIMES
          option value: key, -> val

    $header.find('.nav-item').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true
      updateUrl {'n': $el.data 'nav'}

    $header.find('.subjects .subject').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true
      renderQuestion $el.data 'subject'
      updateUrl {'s': $el.data 'subject'}

  renderNewQuestionPopup = ->

  renderQuestion = (link = "fun", previous = false) ->

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
          {question, vote, title} = child_doc?.val() or {}
          return false unless question and title
          item = localStorage.getItem(child_doc.key()) or {}
          $question = $ teacup.render ->
            div '.question', 'data-key': child_doc.key(), ->
              div '.voting', ->
                div 'data-arrow':'up'
                div ".vote", ->
                div 'data-arrow':'down'
              div '.question-title', -> title
              div '.question-body', -> question
              div '.answers', ->
                for opt in [1..4]
                  ans = child_doc.child("answer_#{opt}").val()
                  continue unless ans
                  div ->
                    span ".answer_#{opt}.text", 'data-next': ans.next, -> ans.text
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
              local_vote = 'none'
              if item.vote > 0
                local_vote = 'up'
              else if item.vote < 0
                local_vote = 'down'
              $question.attr 'data-vote', local_vote


            $question.find('.answers .text').on 'click', (e) ->
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
          div '.open-pop', -> 'Post Something Original'
          div '.modalDialog', ->
            div '.new-question', ->
              h3 -> 'Submitting a new Post'
              span class: 'close', -> 'X'
              form ->
                div '.text-area-container', ->
                  textarea '.question-title', 'data-maxlength': 120, placeholder: "Add title", required: true
                  div '.resizer question-body', -> 'A'
                  div '.characters', -> ''
                div '.text-area-container', ->
                  textarea '.question-body', 'data-maxlength': 250, placeholder: "Add your body", required: true
                  div '.resizer question-body', -> 'A'
                  div '.characters', -> ''
                div '.answers', ->
                  for opt in [1..4]
                    div '.text-area-container', ->
                      required = opt is 1
                      placeholder = if required then 'Put choice here' else 'Put (optional) choice here'
                      textarea ".answer_#{opt}", 'data-maxlength': 140, placeholder: placeholder, required: required
                      div '.resizer', -> 'A'
                      div '.characters', -> ''
                input type:'submit', value: 'submit'
      do ($new_question) ->
        $questions.prepend $new_question
        console.log $new_question.find('.open-pop, .close')
        $new_question.find('.open-pop, .close').on 'click', ->
          $new_question.find('.modalDialog').toggleClass 'visible'
        $new_question.find('textarea').on 'input', (e) ->
          $el = $ e.currentTarget
          maxlength = $el.attr 'data-maxlength'
          str = $el.val().slice 0, maxlength
          $el.val str

          if str.length is 0
            $el.next().html ""
            $el.siblings('.characters').html ''
          else
            $el.next().html "#{str}\n\n"
            $el.siblings('.characters').html maxlength - str.length
          return false

        $new_question.find('form').on 'submit', (e) ->
          if not link
            link = "leaf/#{ref.child('leaf').push().key()}"
          $el = $ e.currentTarget
          new_q = ref.child(link).push()
          new_q_obj = {
            answer_1:
              text: $el.find('textarea.answer_1').val()
            question: $el.find('textarea.question-body').val()
            title: $el.find('textarea.question-title').val()
            created: Firebase.ServerValue.TIMESTAMP
            vote: 0
            vote_inverse: 0
          }

          # handle skips
          c = 2
          for opt in [2..4]
            answer = $el.find("textarea.answer_#{opt}").val()
            continue unless answer
            new_q_obj["answer_#{c}"] = {text: answer}
            c++

          debugger
          new_q.set new_q_obj, ->
            return renderQuestion(link, previous) unless previous
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
  renderQuestion $.url('?s') or 'fun'




