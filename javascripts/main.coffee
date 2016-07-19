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
authedData = null
start_time = 0
end_time = Date.now()

ref.authAnonymously (err, data) ->

  renderHeader = ->

    $header = $('body > .container > .header')
    nav_selected = 'home'
    subject_selected = 'fun'
    times_selected = 'all'

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
      div '.times', ->
        for key, val of TIMES
          div '.time', 'data': {
            time: key
            selected: "#{key is times_selected}"
          }, -> val

    $header.find('.nav-item').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true

    $header.find('.subjects .subject').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true
      renderQuestion $el.data 'subject'

    $header.find('.time').on 'click', (e) ->
      $el = $ e.currentTarget
      $el.siblings().attr 'data-selected', false
      $el.attr 'data-selected', true
      $questions = $('body .questions')
      switch $el.data 'time'
        when 'hour'
          start_time = Date.now() - 60 * 60 * 1000
          end_time = Date.now()
        when 'day'
          start_time = Date.now() - 24 * 60 * 60 * 1000
          end_time = Date.now()
        when 'year'
          start_time = Date.now() - 365 * 24 * 60 * 60 * 1000
          end_time = Date.now()
        when 'all'
          start_time = 0
          end_time = Date.now()

      renderQuestion $questions.data('link'), $questions.data('previous')

  renderLoginPopup = ->

  renderQuestion = (link = "fun", previous = false) ->

    getNextQ = (finish) ->
      if link
        ref.child(link).orderByChild('created').startAt(start_time).endAt(end_time).once 'value', (doc) ->
          # get items
          items = doc.val() or {}

          # convert to array
          new_items = []
          for key, val of items
            val.key = key
            new_items.push val

          # sort array by vote
          new_items = new_items.sort (a, b) ->
            b.vote - a.vote

          # return new items
          finish new_items
      else
        finish null

    $('body .questions-container').html teacup.render ->
      div '.questions'

    $questions = $('body .questions')
    $questions.attr('data-link', link)
    $questions.attr('data-previous', previous)
    $(window).off 'resize', ->
    $(window).on 'resize', ->
      width = Math.floor $(window).width() / 340
      $('.questions-container').css 'max-width', "#{width * 340}px"

    getNextQ (new_items) ->
      if new_items?.length
        new_items.forEach (child_item) ->
          {question, vote, title, key} = child_item or {}
          return false unless question and title
          item = localStorage.getItem(key) or {}
          $question = $ teacup.render ->
            div '.question', 'data-key': key, ->
              div '.voting', ->
                div 'data-arrow':'up'
                div ".vote", ->
                div 'data-arrow':'down'
              div '.question-title', -> title
              div '.question-body', -> question
              flag = true
              div '.answers', ->
                for opt in [1..4]
                  ans = child_item["answer_#{opt}"]
                  continue unless ans
                  div ->
                    span '.text', data: {
                      answer: "answer_#{opt}"
                      next: ans.next
                    }, -> ans.text
                  flag = flag and ans.next
              if not flag
                div '.asterisk', -> 'dead end'

          $questions.append $question
          do ($question) ->
            $question.find('[data-arrow]').on 'click', (e) ->
              $el = $ e.currentTarget
              incriment = if $el.data('arrow') is 'up' then 1 else -1
              item = JSON.parse localStorage.getItem(key) or '{}'
              modified_incriment = incriment
              if item.vote is incriment
                modified_incriment = incriment * -1
                incriment = 0
              else if item.vote is incriment * -1
                modified_incriment = incriment * 2

              item.vote = incriment

              # stupid yes but firebase doesn't support reverse order
              item.vote_inverse = incriment * -1
              localStorage.setItem key, JSON.stringify item

              ref.child("#{link}/#{key}/vote").once 'value', (current_vote_doc) ->
                currentVote = current_vote_doc?.val() or 0
                new_val = currentVote + modified_incriment
                ref.child("#{link}/#{key}/vote").set new_val
                ref.child("#{link}/#{key}/vote_inverse").set new_val * -1

            ref.child("#{link}/#{key}/vote").on 'value', (vote_doc) ->
              new_vote = vote_doc?.val() or 0
              $vote = $question.find('.vote')
              $vote.html "#{new_vote}"
              $vote.toggleClass 'bad', new_vote < 0
              $vote.toggleClass 'good', new_vote > 5

              item = JSON.parse localStorage.getItem(key) or '{}'
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
              key_previous = "#{link}/#{key}/#{$el.data('answer')}"
              ref.child("#{key_previous}/count").transaction (currentCount) ->
                currentCount ?= 0
                return currentCount + 1
              renderQuestion next, key_previous
            return false

      $new_question = $ teacup.render ->
        div '.question', ->
          div '.open-pop', -> if previous then 'add branch at this point' else 'Create new story'
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




