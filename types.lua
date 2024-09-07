---@meta

---@class BlipData
---@field coords vector3
---@field label? string label of the blip. default is 'Hospital'
---@field sprite? number sprite of the blip. default is 61
---@field scale? number scale of the blip. default is 0.8
---@field color? number color of the blip. default is 25

---@class DutyData
---@field coords vector3
---@field groups table
---@field radius? number radius of the zone. default is 1.5

---@class ManagementData
---@field coords vector3
---@field groups table
---@field radius? number radius of the zone. default is 1.5

---@class ArmoryInventoryItem
---@field name string
---@field price number
---@field metadata? table<string, any>
---@field grade? number

---@class ClosetData
---@field shopType string
---@field name string
---@field groups table
---@field inventory ArmoryInventoryItem[]
---@field locations table
---@field radius? number radius of the zone. default is 1.5

---@class PersonalStashData
---@field label string
---@field coords vector3
---@field groups table
---@field radius? number radius of the zone. default is 1.5
---@field slots? number number of slots in stash. default is 100
---@field weight? number weight in grams in stash. default is 100000 (100kg)

---@class CatalogueItem
---@field name string
---@field grade number

---@class VehicleData
---@field coords vector3
---@field spawn vector4
---@field radius number
---@field catalogue CatalogueItem[]
---@field groups table

---@class HospitalData
---@field blip BlipData
---@field duty DutyData[]
---@field management ManagementData[]
---@field armory ClosetData[]
---@field personalStash PersonalStashData[]
---@field garage VehicleData[]
---@field helipad VehicleData[]