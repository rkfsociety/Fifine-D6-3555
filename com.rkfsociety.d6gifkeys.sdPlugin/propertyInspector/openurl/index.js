/// <reference path="../utils/common.js" />
/// <reference path="../utils/action.js" />

const $local = false, $back = false, $dom = {
    main: $('.sdpi-wrapper')
};

const $propEvent = {
    didReceiveSettings() {
        $('#url').value = $settings.url ?? '';
    }
};

$('#url').on('change', () => {
    $settings.url = $('#url').value.trim();
});
