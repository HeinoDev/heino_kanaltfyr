local Webhook = ''

KanaltfyrLogs = {}

local function SendWebhook(Message)
    local Payload = {
        username = 'Heino-Kanaltfyr',
        embeds = { { title = 'Kanaltfyr', description = Message, color = 3447003 } }
    }

    PerformHttpRequest(Webhook, function() end, 'POST', json.encode(Payload), { ['Content-Type'] = 'application/json' })
end

function KanaltfyrLogs.Sold(Source, TraderName, ItemName, Amount, Payout)
    if Webhook == '' then return end

    local message = ('**Player:** %s (%d)\n**Trader:** %s\n**Item:** %s x%d\n**Paid:** %d'):format(GetPlayerName(Source) or 'Unknown', Source, TraderName, ItemName, Amount, Payout)

    SendWebhook(message)
end
