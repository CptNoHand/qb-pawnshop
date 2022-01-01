local QBCore = exports['qb-core']:GetCoreObject()
local isMelting = false
local canTake = false
local meltedItem = {}
local meltTime

CreateThread(function()
	local blip = AddBlipForCoord(Config.PawnLocation.x, Config.PawnLocation.y, Config.PawnLocation.z)
	SetBlipSprite(blip, 431)
	SetBlipDisplay(blip, 4)
	SetBlipScale(blip, 0.7)
	SetBlipAsShortRange(blip, true)
	SetBlipColour(blip, 5)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName("Pawn Shop")
	EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('qb-pawnshop:client:openMenu', function()
	if Config.UseTimes then
		if GetClockHours() >= Config.TimeOpen and GetClockHours() <= Config.TimeClosed then
			local pawnShop = {
				{
					header = "Pawn Shop",
					isMenuHeader = true,
				},
				{
					header = "Pawn Items",
					txt = "Open the Pawn Shop",
					params = {
						event = "qb-pawnshop:client:openPawn",
						args = {
							items = Config.PawnItems
						}
					}
				}
			}
			if not isMelting then
				pawnShop[#pawnShop + 1] = {
					header = "Melt Items",
					txt = "Open the Melting Shop",
					params = {
						event = "qb-pawnshop:client:openMelt",
						args = {
							items = Config.MeltingItems
						}
					}
				}
			end
			if canTake then
				pawnShop[#pawnShop + 1] = {
					header = "Pickup Melted Items",
					txt = "",
					params = {
						isServer = true,
						event = "qb-pawnshop:server:pickupMelted",
						args = {
							items = meltedItem
						}
					}
				}
			end
			exports['qb-menu']:openMenu(pawnShop)
		else
			QBCore.Functions.Notify("Pawnshop is closed. Come back between "..Config.TimeOpen..":00 AM - "..Config.TimeClosed..':00 PM')
		end
	else
		local pawnShop = {
			{
				header = "Pawn Shop Menu",
				isMenuHeader = true,
			},
			{
				header = "Pawn Items",
				txt = "Open the Pawn Shop",
				params = {
					event = "qb-pawnshop:client:openPawn",
					args = {
						items = Config.PawnItems
					}
				}
			}
		}
		if not isMelting then
			pawnShop[#pawnShop + 1] = {
				header = "Melt Items",
				txt = "Open the Melting Shop",
				params = {
					event = "qb-pawnshop:client:openMelt",
					args = {
						items = Config.MeltingItems
					}
				}
			}
		end
		if canTake then
			pawnShop[#pawnShop + 1] = {
				header = "Pickup Melted Items",
				txt = "",
				params = {
					isServer = true,
					event = "qb-pawnshop:server:pickupMelted",
					args = {
						items = meltedItem
					}
				}
			}
		end
		exports['qb-menu']:openMenu(pawnShop)
	end
end)

RegisterNetEvent('qb-pawnshop:client:openPawn', function(data)
	QBCore.Functions.TriggerCallback('qb-pawnshop:server:getInv', function(inventory)
		local PlyInv = inventory
		local pawnMenu = {
			{
				header = "Pawn Menu",
				isMenuHeader = true,
			}
		}
		for k,v in pairs(PlyInv) do
			for i = 1, #data.items do
				if v.name == data.items[i].item then
					pawnMenu[#pawnMenu +1] = {
						header = QBCore.Shared.Items[v.name].label,
						txt = "Selling Price: $"..data.items[i].price,
						params = {
							event = "qb-pawnshop:client:pawnitems",
							args = {
								label = QBCore.Shared.Items[v.name].label,
								price = data.items[i].price,
								name = v.name,
								amount = v.amount
							}
						}
					}
				end
			end
		end
		exports['qb-menu']:openMenu(pawnMenu)
	end)
end)

RegisterNetEvent('qb-pawnshop:client:openMelt', function(data)
	QBCore.Functions.TriggerCallback('qb-pawnshop:server:getInv', function(inventory)
		local PlyInv = inventory
		local meltMenu = {
			{
				header = "Melting Menu",
				isMenuHeader = true,
			}
		}
		for k,v in pairs(PlyInv) do
			for i = 1, #data.items do
				if v.name == data.items[i].item then
					meltMenu[#meltMenu +1] = {
						header = QBCore.Shared.Items[v.name].label,
						txt = "Melt "..QBCore.Shared.Items[v.name].label,
						params = {
							event = "qb-pawnshop:client:meltItems",
							args = {
								label = QBCore.Shared.Items[v.name].label,
								reward = data.items[i].rewards,
								name = v.name,
								amount = v.amount,
								time = data.items[i].meltTime
							}
						}
					}
				end
			end
		end
		exports['qb-menu']:openMenu(meltMenu)
	end)
end)

RegisterNetEvent("qb-pawnshop:client:pawnitems", function(item)
	local sellingItem = exports['qb-input']:ShowInput({
		header = "Pawn Item",
		submitText = "Sell Item",
		inputs = {
			{
				type = 'number',
				isRequired = false,
				name = 'amount',
				text = 'max amount '..item.amount
			}
		}
	})
	if sellingItem then
		if not sellingItem.amount then
			return
		end
		TriggerServerEvent('qb-pawnshop:server:sellPawnItems', item.name, sellingItem.amount, item.price)
	end
end)

RegisterNetEvent('qb-pawnshop:client:meltItems', function(item)
	local meltingItem = exports['qb-input']:ShowInput({
		header = "Melt Item",
		submitText = "Melt",
		inputs = {
			{
				type = 'number',
				isRequired = false,
				name = 'amount',
				text = 'Max Amount '..item.amount
			}
		}
	})
	if meltingItem then
		if not meltingItem.amount then
			return
		end
		if meltingItem.amount ~= nil then
			if tonumber(meltingItem.amount) > 0 then
				meltTime = 0
				TriggerServerEvent('qb-pawnshop:server:meltItemRemove', item.name, meltingItem.amount)
				meltTime = (tonumber(meltingItem.amount) * item.time)
				TriggerEvent('qb-pawnshop:client:startMelting', item, tonumber(meltingItem.amount), (meltTime* 60000))
				QBCore.Functions.Notify("Give me "..meltTime.." minutes and I'll have your stuff melted...", "success")
			else
				QBCore.Functions.Notify("You didn't give me anything to melt...", "error")
			end
		else
			QBCore.Functions.Notify("You didn't give me anything to melt...", "error")
		end
	end
end)

RegisterNetEvent('qb-pawnshop:client:startMelting', function(item, meltingAmount, meltTime)
    if not isMelting then
        isMelting = true
        CreateThread(function()
            while isMelting do
                if LocalPlayer.state.isLoggedIn then
                    meltTime = meltTime - 1
                    if meltTime <= 0 then
                        canTake = true
                        isMelting = false
						table.insert(meltedItem, {item = item, amount = meltingAmount})
						if Config.SendMeltingEmail then
							TriggerServerEvent('qb-phone:server:sendNewMail', {
								sender = Config.EmailSender,
								subject = Config.EmailSubject,
								message = Config.EmailMessage,
								button = {}
							})
						else
							QBCore.Functions.Notify("Your items have been melted. Come pick them up...", "success")
						end
                    end
                else
                    break
                end
                Wait(1000)
            end
        end)
    end
end)

RegisterNetEvent('qb-pawnshop:client:resetPickup', function()
	canTake = false
end)
