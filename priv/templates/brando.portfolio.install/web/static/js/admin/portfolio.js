"use strict";

import $ from "jquery";
import {Utils, Accordion, vex, bI18n} from "brando";

const MARK_AS_COVER = 1;
const UNMARK_AS_COVER = 0;

var imagePool = [];

class Portfolio {
    static setup() {
        this.getHash();
        this.deleteListener();
        this.coverListener();
        this.imageSelectionListener();
        this.imagePropertiesListener();
        this.setupI18n();
    }

    static setupI18n() {
        const nbTranslations = {
            'delete_confirm': 'Er du sikker på at du vil slette disse bildene?',
            'delete_images': 'Slett bilder',
            'delete_selected': 'Slett valgte bilder',
            'deleting': 'Sletter...',
        };
        const enTranslations = {
            'delete_confirm': 'Are you sure you want to delete these images?',
            'delete_images': 'Delete images',
            'delete_selected': 'Delete selected images',
            'deleting': 'Deleting...',
        };
        bI18n.i18next.addResourceBundle('nb', 'portfolio', nbTranslations);
        bI18n.i18next.addResourceBundle('en', 'portfolio', enTranslations);
    }

    static getHash() {
        let hash = document.location.hash
        if (hash) {
            // show the tab
            Accordion.activateTab("#tab-" + hash.slice(1));
        }
    }

    static imageSelectionListener() {
        var that = this;
        $('.image-selection-pool img').click(function(e) {
          if ($(this).hasClass('selected')) {
            // remove from selected pool
            var pos;
            for (var i = 0; i < imagePool.length; i++) {
              if ( imagePool[i] == $(this).attr('data-id')) {
                pos = i;
                break;
              }
            }
            imagePool.splice(pos, 1);
          } else {
            // add to selected pool
            if (!imagePool) {
              imagePool = new Array();
            }
            imagePool.push($(this).attr('data-id'));
          }
          $(this).toggleClass('selected');

          that.checkButtonEnable(this);
          that.checkMarkCoverButtonEnable(this);
          that.checkUnmarkCoverButtonEnable(this);
        });
    }

    static imagePropertiesListener() {
        var that = this;

        $(document).on({
            mouseenter: function(){
                $(this).find('.overlay').css('visibility', 'visible');
            },
            mouseleave: function(){
                $(this).find('.overlay').css('visibility', 'hidden');
            }
        }, '.image-wrapper');

        $(document).on('click', '.edit-properties', function(e) {
            e.preventDefault();

            var attrs,
                $content = $('<div>'),
                $form,
                $img = $(this).parent().parent().find('img').clone();

            vex.dialog.open({
                message: '',
                input: function() {
                    attrs = that._buildAttrs($img.data());
                    $content.append($img).append(attrs);
                    return $content;
                },
                callback: function(form) {
                    if (form === false) {
                      return console.log('Cancelled');
                    }
                    var id = form.id;
                    delete form.id;
                    var data = {
                        form: form,
                        id: id
                    }
                    that._submitProperties(data);
                }
            });
        });
    }

    static _submitProperties(data) {
        $.ajax({
            headers: {Accept : "application/json; charset=utf-8"},
            type: "POST",
            data: data,
            url: Utils.addToPathName('set-properties'),
        }).done($.proxy(function(data) {
            /**
             * Callback after confirming.
             */
            if (data.status == '200') {
                // success
                var $img = $('.image-serie img[data-id=' + data.id + ']');
                $.each(data.attrs, function(attr, val) {
                    $img.attr('data-' + attr, val);
                });
            }
        }));
    }

    static _buildAttrs(data) {
        var that = this,
            ret = '';

        $.each(data, function(attr, val) {
            if (attr == 'id') {
                ret += '<input name="id" type="hidden" value="' + val + '" />';
            } else {
                ret += '<div><label>' + that._capitalize(attr) + '</label>' +
                       '<input name="' + attr + '" type="text" value="' + val + '" /></div>'
            }
        });

        return ret;
    }

    static _capitalize(word) {
       return $.camelCase("-" + word);
    }

    static checkButtonEnable(scope) {
        let $scope = $(scope).parent().parent();
        let $btn = $('.delete-selected-images', $scope);

        if (imagePool.length > 0) {
            $btn.removeAttr('disabled');
        } else {
            $btn.attr('disabled', 'disabled');
        }
    }

    static checkMarkCoverButtonEnable(scope) {
        let $scope = $(scope).parent().parent();
        let $btn = $('.mark-as-cover', $scope);

        if (imagePool.length == 1) {
            let $image = $(`.image-selection-pool img[data-id=${imagePool[0]}]`)
            if ($image.attr('data-cover') == 0) {
                $btn.removeAttr('disabled');
                return true;
            }
        }
        $btn.attr('disabled', 'disabled');
    }

    static checkUnmarkCoverButtonEnable(scope) {
        let $scope = $(scope).parent().parent();
        let $btn = $('.unmark-as-cover', $scope);

        if (imagePool.length == 1) {
            let $image = $(`.image-selection-pool img[data-id=${imagePool[0]}]`)
            if ($image.attr('data-cover') == 1) {
                $btn.removeAttr('disabled');
                return true;
            }
        }
        $btn.attr('disabled', 'disabled');
    }

    static _callMarkAsCover(images, action) {
        $.ajax({
            headers: {Accept: "application/json; charset=utf-8"},
            type: "POST",
            url: Utils.addToPathName('mark-as-cover'),
            data: {ids: images, action: action},
            success: this.markCoverCallback,
        });
    }

    static coverListener() {
        var that = this;
        $('.mark-as-cover').click(function(e) {
            e.preventDefault();
            that._callMarkAsCover(imagePool, MARK_AS_COVER);
        });

        $('.unmark-as-cover').click(function(e) {
            e.preventDefault();
            that._callMarkAsCover(imagePool, UNMARK_AS_COVER);
        });
    }

    static markCoverCallback(data) {
        if (data.status == 200) {
            let $image = $('img[data-id=' + data.id + ']');
            let $scope = $image.parent().parent();

            $('.image-selection-pool img').removeAttr('class');
            $('img[data-cover=1]', $scope).attr('data-cover', 0);

            if (data.action == "1") {
                $image.attr('data-cover', 1);
            }

            imagePool = [];
        }
    }

    static deleteListener() {
        var that = this;
        $('.delete-selected-images').click(function(e) {
            e.preventDefault();
            vex.dialog.confirm({
                message: bI18n.i18next.t('portfolio:delete_confirm'),
                callback: function(value) {
                    if (value) {
                        $(this).removeClass("btn-danger").addClass("btn-warning").html(bI18n.i18next.t('portfolio:deleting'));
                        $.ajax({
                            headers: {Accept : "application/json; charset=utf-8"},
                            type: "POST",
                            url: Utils.addToPathName('delete-selected-images'),
                            data: {ids: imagePool},
                            success: that.deleteSuccess,
                        });
                    }
                }
            });
        });
    }

    static deleteSuccess(data) {
        if (data.status == 200) {
            $(".delete-selected-images")
                .removeClass("btn-warning")
                .addClass("btn-danger")
                .html(bI18n.i18next.t('portfolio:delete_images'))
                .attr('disabled', 'disabled');

            for (var i = 0; i < data.ids.length; i++) {
                $(`.image-selection-pool img[data-id=${data.ids[i]}]`).fadeOut();
            }

            imagePool = [];
        }
    }
}

$(() => {
    Portfolio.setup();
});

export default Portfolio;
