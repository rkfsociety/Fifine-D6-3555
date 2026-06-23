/// <reference path="../utils/common.js" />
/// <reference path="../utils/action.js" />

const $local = false, $back = false, $dom = {
    main: $('.sdpi-wrapper')
};

const $propEvent = {
    didReceiveSettings() {
        $('#step').value = $settings.step ?? 1;
        $('#count').value = $settings.count ?? 0;
    }
};

$('#step').on('change', () => {
    $settings.step = Number($('#step').value) || 1;
});

$('#count').on('change', () => {
    $settings.count = Number($('#count').value) || 0;
});

$('#reset').on('click', () => {
    $settings.count = 0;
    $('#count').value = 0;
});
