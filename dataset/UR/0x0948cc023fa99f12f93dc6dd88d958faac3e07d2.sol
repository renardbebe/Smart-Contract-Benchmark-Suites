 

library OwnershipTypes{
    using Serializer for Serializer.DataComponent;

    struct Ownership
    {
        address m_Owner;  
        uint32 m_OwnerInventoryIndex;  
    }

    function SerializeOwnership(Ownership ownership) internal pure returns (bytes32)
    {
        Serializer.DataComponent memory data;
        data.WriteAddress(0, ownership.m_Owner);
        data.WriteUint32(20, ownership.m_OwnerInventoryIndex);

        return data.m_Raw;
    }

    function DeserializeOwnership(bytes32 raw) internal pure returns (Ownership)
    {
        Ownership memory ownership;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        ownership.m_Owner = data.ReadAddress(0);
        ownership.m_OwnerInventoryIndex = data.ReadUint32(20);

        return ownership;
    }
}
library LibStructs{
    using Serializer for Serializer.DataComponent;
     

    struct Hero {
        uint16 stockID;
        uint8 rarity;
        uint16 hp;
        uint16 atk;
        uint16 def;
        uint16 agi;
        uint16 intel;
        uint16 cHp;
         
         
         
         
         

        uint8 isForSale;
        uint8 lvl;
        uint16 xp;
    }
    struct StockHero {uint16 price;uint8 stars;uint8 mainOnePosition;uint8 mainTwoPosition;uint16 stock;uint8 class;}

    function SerializeHero(Hero hero) internal pure returns (bytes32){
        Serializer.DataComponent memory data;
        data.WriteUint16(0, hero.stockID);
        data.WriteUint8(2, hero.rarity);
         
         
        data.WriteUint16(4, hero.hp);
        data.WriteUint16(6, hero.atk);
        data.WriteUint16(8, hero.def);
        data.WriteUint16(10, hero.agi);
        data.WriteUint16(12, hero.intel);
        data.WriteUint16(14, hero.cHp);

         
         
         
         

        data.WriteUint8(20, hero.isForSale);
        data.WriteUint8(21, hero.lvl);
        data.WriteUint16(23, hero.xp);

        return data.m_Raw;
    }
    function DeserializeHero(bytes32 raw) internal pure returns (Hero){
        Hero memory hero;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        hero.stockID = data.ReadUint16(0);
         
        hero.rarity = data.ReadUint8(2);
         
        hero.hp = data.ReadUint16(4);
        hero.atk = data.ReadUint16(6);
        hero.def = data.ReadUint16(8);
        hero.agi = data.ReadUint16(10);
        hero.intel = data.ReadUint16(12);
        hero.cHp = data.ReadUint16(14);

         
         
         
         

        hero.isForSale = data.ReadUint8(20);
        hero.lvl = data.ReadUint8(21);
        hero.xp = data.ReadUint16(23);

        return hero;
    }
    function SerializeStockHero(StockHero stockhero) internal pure returns (bytes32){
         

        Serializer.DataComponent memory data;
        data.WriteUint16(0, stockhero.price);
        data.WriteUint8(2, stockhero.stars);
        data.WriteUint8(3, stockhero.mainOnePosition);
        data.WriteUint8(4, stockhero.mainTwoPosition);
        data.WriteUint16(5, stockhero.stock);
        data.WriteUint8(7, stockhero.class);


        return data.m_Raw;
    }
    function DeserializeStockHero(bytes32 raw) internal pure returns (StockHero){
        StockHero memory stockhero;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        stockhero.price = data.ReadUint16(0);
        stockhero.stars = data.ReadUint8(2);
        stockhero.mainOnePosition = data.ReadUint8(3);
        stockhero.mainTwoPosition = data.ReadUint8(4);
        stockhero.stock = data.ReadUint16(5);
        stockhero.class = data.ReadUint8(7);

        return stockhero;
    }
     
    struct Item {
        uint16 stockID;
        uint8 lvl;
        uint8 rarity;
        uint16 hp;
        uint16 atk;
        uint16 def;
        uint16 agi;
        uint16 intel;

        uint8 critic;
        uint8 healbonus;
        uint8 atackbonus;
        uint8 defensebonus;

        uint8 isForSale;
        uint8 grade;
    }
    struct StockItem {uint16 price;uint8 stars;uint8 lvl;uint8 mainOnePosition;uint8 mainTwoPosition;uint16[5] stats;uint8[4] secstats;uint8 cat;uint8 subcat;}  

    function SerializeItem(Item item) internal pure returns (bytes32){
        Serializer.DataComponent memory data;

        data.WriteUint16(0, item.stockID);
        data.WriteUint8(4, item.lvl);
        data.WriteUint8(5, item.rarity);
        data.WriteUint16(6, item.hp);
        data.WriteUint16(8, item.atk);
        data.WriteUint16(10, item.def);
        data.WriteUint16(12, item.agi);
        data.WriteUint16(14, item.intel);
         

        data.WriteUint8(16, item.critic);
        data.WriteUint8(17, item.healbonus);
        data.WriteUint8(18, item.atackbonus);
        data.WriteUint8(19, item.defensebonus);

        data.WriteUint8(20, item.isForSale);
        data.WriteUint8(21, item.grade);


        return data.m_Raw;

    }
    function DeserializeItem(bytes32 raw) internal pure returns (Item){
        Item memory item;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        item.stockID = data.ReadUint16(0);

        item.lvl = data.ReadUint8(4);
        item.rarity = data.ReadUint8(5);
        item.hp = data.ReadUint16(6);
        item.atk = data.ReadUint16(8);
        item.def = data.ReadUint16(10);
        item.agi = data.ReadUint16(12);
        item.intel = data.ReadUint16(14);

        item.critic = data.ReadUint8(16);
        item.healbonus = data.ReadUint8(17);
        item.atackbonus = data.ReadUint8(18);
        item.defensebonus = data.ReadUint8(19);

        item.isForSale = data.ReadUint8(20);
        item.grade = data.ReadUint8(21);


        return item;
    }
    function SerializeStockItem(StockItem stockitem) internal pure returns (bytes32){
         
         

        Serializer.DataComponent memory data;
        data.WriteUint16(0, stockitem.price);
        data.WriteUint8(2, stockitem.stars);
        data.WriteUint8(3, stockitem.lvl);
        data.WriteUint8(4, stockitem.mainOnePosition);
        data.WriteUint8(5, stockitem.mainTwoPosition);
         
         
        data.WriteUint16(6, stockitem.stats[0]);
        data.WriteUint16(8, stockitem.stats[1]);
        data.WriteUint16(10, stockitem.stats[2]);
        data.WriteUint16(12, stockitem.stats[3]);
        data.WriteUint16(14, stockitem.stats[4]);
         
        data.WriteUint8(16, stockitem.secstats[0]);
        data.WriteUint8(17, stockitem.secstats[1]);
        data.WriteUint8(18, stockitem.secstats[2]);
        data.WriteUint8(19, stockitem.secstats[3]);

        data.WriteUint8(20, stockitem.cat);
        data.WriteUint8(21, stockitem.subcat);


        return data.m_Raw;
    }
    function DeserializeStockItem(bytes32 raw) internal pure returns (StockItem){
        StockItem memory stockitem;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        stockitem.price = data.ReadUint16(0);
        stockitem.stars = data.ReadUint8(2);
        stockitem.lvl = data.ReadUint8(3);
        stockitem.mainOnePosition = data.ReadUint8(4);
        stockitem.mainTwoPosition = data.ReadUint8(5);
         

        stockitem.stats[0] = data.ReadUint16(6);
        stockitem.stats[1] = data.ReadUint16(8);
        stockitem.stats[2] = data.ReadUint16(10);
        stockitem.stats[3] = data.ReadUint16(12);
        stockitem.stats[4] = data.ReadUint16(14);

        stockitem.secstats[0] = data.ReadUint8(16);
        stockitem.secstats[1] = data.ReadUint8(17);
        stockitem.secstats[2] = data.ReadUint8(18);
        stockitem.secstats[3] = data.ReadUint8(19);

        stockitem.cat = data.ReadUint8(20);
        stockitem.subcat = data.ReadUint8(21);

        return stockitem;
    }

    struct Action {uint16 actionID;uint8 actionType;uint16 finneyCost;uint32 cooldown;uint8 lvl;uint8 looted;uint8 isDaily;}
    function SerializeAction(Action action) internal pure returns (bytes32){
        Serializer.DataComponent memory data;
        data.WriteUint16(0, action.actionID);
        data.WriteUint8(2, action.actionType);
        data.WriteUint16(3, action.finneyCost);
        data.WriteUint32(5, action.cooldown);
        data.WriteUint8(9, action.lvl);
        data.WriteUint8(10, action.looted);
        data.WriteUint8(11, action.isDaily);

        return data.m_Raw;
    }
    function DeserializeAction(bytes32 raw) internal pure returns (Action){
        Action memory action;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        action.actionID = data.ReadUint16(0);
        action.actionType = data.ReadUint8(2);
        action.finneyCost = data.ReadUint16(3);
        action.cooldown = data.ReadUint32(5);
        action.lvl = data.ReadUint8(9);
        action.looted = data.ReadUint8(10);
        action.isDaily = data.ReadUint8(11);

        return action;
    }

    struct Mission {uint8 dificulty;uint16[4] stockitemId_drops;uint16[5] statsrequired;uint16 count;}
    function SerializeMission(Mission mission) internal pure returns (bytes32){
        Serializer.DataComponent memory data;
        data.WriteUint8(0, mission.dificulty);
        data.WriteUint16(1, mission.stockitemId_drops[0]);
        data.WriteUint16(5, mission.stockitemId_drops[1]);
        data.WriteUint16(9, mission.stockitemId_drops[2]);
        data.WriteUint16(13, mission.stockitemId_drops[3]);

        data.WriteUint16(15, mission.statsrequired[0]);
        data.WriteUint16(17, mission.statsrequired[1]);
        data.WriteUint16(19, mission.statsrequired[2]);
        data.WriteUint16(21, mission.statsrequired[3]);
        data.WriteUint16(23, mission.statsrequired[4]);

        data.WriteUint16(25, mission.count);

        return data.m_Raw;
    }
    function DeserializeMission(bytes32 raw) internal pure returns (Mission){
        Mission memory mission;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        mission.dificulty = data.ReadUint8(0);
        mission.stockitemId_drops[0] = data.ReadUint16(1);
        mission.stockitemId_drops[1] = data.ReadUint16(5);
        mission.stockitemId_drops[2] = data.ReadUint16(9);
        mission.stockitemId_drops[3] = data.ReadUint16(13);

        mission.statsrequired[0] = data.ReadUint16(15);
        mission.statsrequired[1] = data.ReadUint16(17);
        mission.statsrequired[2] = data.ReadUint16(19);
        mission.statsrequired[3] = data.ReadUint16(21);
        mission.statsrequired[4] = data.ReadUint16(23);

        mission.count = data.ReadUint16(25);

        return mission;
    }

    function toWei(uint80 price) public returns(uint256 value){
        value = price;
        value = value * 1 finney;

    }

}
library GlobalTypes{
    using Serializer for Serializer.DataComponent;

    struct Global
    {
        uint32 m_LastHeroId;  
        uint32 m_LastItem;  
        uint8 m_Unused8;  
        uint8 m_Unused9;  
        uint8 m_Unused10;  
        uint8 m_Unused11;  
    }

    function SerializeGlobal(Global global) internal pure returns (bytes32)
    {
        Serializer.DataComponent memory data;
        data.WriteUint32(0, global.m_LastHeroId);
        data.WriteUint32(4, global.m_LastItem);
        data.WriteUint8(8, global.m_Unused8);
        data.WriteUint8(9, global.m_Unused9);
        data.WriteUint8(10, global.m_Unused10);
        data.WriteUint8(11, global.m_Unused11);

        return data.m_Raw;
    }

    function DeserializeGlobal(bytes32 raw) internal pure returns (Global)
    {
        Global memory global;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        global.m_LastHeroId = data.ReadUint32(0);
        global.m_LastItem = data.ReadUint32(4);
        global.m_Unused8 = data.ReadUint8(8);
        global.m_Unused9 = data.ReadUint8(9);
        global.m_Unused10 = data.ReadUint8(10);
        global.m_Unused11 = data.ReadUint8(11);

        return global;
    }


}
library MarketTypes{
    using Serializer for Serializer.DataComponent;

    struct MarketListing
    {
        uint128 m_Price;  
    }

    function SerializeMarketListing(MarketListing listing) internal pure returns (bytes32)
    {
        Serializer.DataComponent memory data;
        data.WriteUint128(0, listing.m_Price);

        return data.m_Raw;
    }

    function DeserializeMarketListing(bytes32 raw) internal pure returns (MarketListing)
    {
        MarketListing memory listing;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        listing.m_Price = data.ReadUint128(0);

        return listing;
    }
}
library Serializer{
    struct DataComponent
    {
        bytes32 m_Raw;
    }

    function ReadUint8(DataComponent memory self, uint32 offset) internal pure returns (uint8)
    {
        return uint8((self.m_Raw >> (offset * 8)) & 0xFF);
    }

    function WriteUint8(DataComponent memory self, uint32 offset, uint8 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint16(DataComponent memory self, uint32 offset) internal pure returns (uint16)
    {
        return uint16((self.m_Raw >> (offset * 8)) & 0xFFFF);
    }

    function WriteUint16(DataComponent memory self, uint32 offset, uint16 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint32(DataComponent memory self, uint32 offset) internal pure returns (uint32)
    {
        return uint32((self.m_Raw >> (offset * 8)) & 0xFFFFFFFF);
    }

    function WriteUint32(DataComponent memory self, uint32 offset, uint32 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint64(DataComponent memory self, uint32 offset) internal pure returns (uint64)
    {
        return uint64((self.m_Raw >> (offset * 8)) & 0xFFFFFFFFFFFFFFFF);
    }

    function WriteUint64(DataComponent memory self, uint32 offset, uint64 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint80(DataComponent memory self, uint32 offset) internal pure returns (uint80)
    {
        return uint80((self.m_Raw >> (offset * 8)) & 0xFFFFFFFFFFFFFFFFFFFF);
    }

    function WriteUint80(DataComponent memory self, uint32 offset, uint80 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint128(DataComponent memory self, uint128 offset) internal pure returns (uint128)
    {
        return uint128((self.m_Raw >> (offset * 8)) & 0xFFFFFFFFFFFFFFFFFFFF);
    }

    function WriteUint128(DataComponent memory self, uint32 offset, uint128 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadAddress(DataComponent memory self, uint32 offset) internal pure returns (address)
    {
        return address((self.m_Raw >> (offset * 8)) & (
        (0xFFFFFFFF << 0)  |
        (0xFFFFFFFF << 32) |
        (0xFFFFFFFF << 64) |
        (0xFFFFFFFF << 96) |
        (0xFFFFFFFF << 128)
        ));
    }

    function WriteAddress(DataComponent memory self, uint32 offset, address value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }
}
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
library SafeMath32 {

     
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
         
        uint32 c = a / b;
         
        return c;
    }

     
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}
library SafeMath16 {

     
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
         
        uint16 c = a / b;
         
        return c;
    }

     
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}
library SafeMath8 {

     
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
         
        uint8 c = a / b;
         
        return c;
    }

     
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract HeroHelperSup
{
    address public m_Owner;
    address public m_Owner2;
    uint8 lvlCap = 20;

    bool public m_Paused;
    AbstractDatabase m_Database= AbstractDatabase(0x095cbb73c75d4e1c62c94e0b1d4d88f8194b1941);
    address public bitGuildAddress = 0x89a196a34B7820bC985B98096ED5EFc7c4DC8363;
    mapping(uint32 => uint)  public timeLimitPerStockHeroID;
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;

    modifier OnlyOwner(){
        require(msg.sender == m_Owner || msg.sender == m_Owner2);
        _;
    }

    modifier onlyOwnerOf(uint _hero_id) {
        OwnershipTypes.Ownership memory ownership = OwnershipTypes.DeserializeOwnership(m_Database.Load(NullAddress, OwnershipHeroCategory, _hero_id));
        require(ownership.m_Owner == msg.sender);
        _;
    }

    address constant NullAddress = 0;

    uint256 constant GlobalCategory = 0;

     
    uint256 constant HeroCategory = 1;
    uint256 constant HeroStockCategory = 2;
    uint256 constant InventoryHeroCategory = 3;

    uint256 constant OwnershipHeroCategory = 10;
    uint256 constant OwnershipItemCategory = 11;
    uint256 constant OwnershipAbilitiesCategory = 12;

     
    uint256 constant ProfitFundsCategory = 14;
    uint256 constant WithdrawalFundsCategory = 15;
    uint256 constant HeroMarketCategory = 16;

     
    uint256 constant ActionCategory = 20;
    uint256 constant MissionCategory = 17;
    uint256 constant ActionHeroCategory = 18;

     
    uint256 constant ReferalCategory = 237;

    using Serializer for Serializer.DataComponent;

    function ChangeAddressHeroTime(uint32 HeroStockID,uint timeLimit) public OnlyOwner()
    {
        timeLimitPerStockHeroID[HeroStockID] = timeLimit;
    }
    
    function ChangeOwner(address new_owner) public OnlyOwner(){
        m_Owner = new_owner;
    }

    function ChangeOwner2(address new_owner) public OnlyOwner(){
        m_Owner2 = new_owner;
    }

    function ChangeDatabase(address db) public OnlyOwner(){
        m_Database = AbstractDatabase(db);
    }

    function HeroHelperSup() public{
        m_Owner = msg.sender;
        m_Paused = true;
    }

    function changeLvlCap(uint8 newLvl) public OnlyOwner(){
        lvlCap = newLvl;
    }

    function GetHeroStockStats(uint16 stockhero_id) public view returns (uint64 price,uint8 stars,uint8 mainOnePosition,uint8 mainTwoPosition,uint16 stock,uint8 class){
        LibStructs.StockHero memory stockhero = GetHeroStock(stockhero_id);
        price = stockhero.price;
        stars = stockhero.stars;
        mainOnePosition = stockhero.mainOnePosition;
        mainTwoPosition = stockhero.mainTwoPosition;
        stock = stockhero.stock;
        class = stockhero.class;

    }
    function GetHeroStock(uint16 stockhero_id)  private view returns (LibStructs.StockHero){
        LibStructs.StockHero memory stockhero = LibStructs.DeserializeStockHero(m_Database.Load(NullAddress, HeroStockCategory, stockhero_id));
        return stockhero;
    }

    function GetHeroCount(address _owner) public view returns (uint32){
        return uint32(m_Database.Load(_owner, HeroCategory, 0));
    }
    function GetHero(uint32 hero_id) public view returns(uint16[14] values){

        LibStructs.Hero memory hero = LibStructs.DeserializeHero(m_Database.Load(NullAddress, HeroCategory, hero_id));
        bytes32 base = m_Database.Load(NullAddress, ActionHeroCategory, hero_id);
        LibStructs.Action memory action = LibStructs.DeserializeAction( base );

        uint8 actStat = 0;
        uint16 minLeft = 0;
        if(uint32(base) != 0){
            if(action.cooldown > now){
                actStat = 1;
                minLeft = uint16( (action.cooldown - now).div(60 seconds));
            }
        }
        values = [hero.stockID,uint16(hero.rarity),hero.hp,hero.atk,hero.def,hero.agi,hero.intel,hero.lvl,hero.isForSale,hero.cHp,hero.xp,action.actionID,uint16(actStat),minLeft];

    }


    event heroLeveledUp(address sender, uint32 hero_id);
    event BuyStockHeroEvent(address indexed buyer, uint32 stock_id, uint32 hero_id);

    function BuyStockHeroP1(uint16 stock_id) public payable {

        LibStructs.StockHero memory prehero = GetHeroStock(stock_id);
        uint256 valuePrice = prehero.price;
        valuePrice = valuePrice.mul( 10 finney );

        require(msg.value  == valuePrice  && now < timeLimitPerStockHeroID[stock_id] && prehero.stars >= 4);

        BuyStockHeroP2(msg.sender,stock_id,5,valuePrice);

    }
    function BuyStockHeroP2(address target,uint16 stock_id,uint8 rarity,uint valuePrice) internal{

        uint256 inventory_count;
        LibStructs.StockHero memory prehero = GetHeroStock(stock_id);
        LibStructs.Hero memory hero = buyHero(prehero,stock_id,rarity);
        GlobalTypes.Global memory global = GlobalTypes.DeserializeGlobal(m_Database.Load(NullAddress, GlobalCategory, 0));

        global.m_LastHeroId = global.m_LastHeroId.add(1);
        uint32 next_hero_id = global.m_LastHeroId;
        inventory_count = GetInventoryHeroCount(target);

        inventory_count = inventory_count.add(1);


        OwnershipTypes.Ownership memory ownership;
        ownership.m_Owner = target;
        ownership.m_OwnerInventoryIndex = uint32(inventory_count.sub(1));

        m_Database.Store(target, InventoryHeroCategory, inventory_count, bytes32(next_hero_id));  
        m_Database.Store(target, InventoryHeroCategory, 0, bytes32(inventory_count));  

        m_Database.Store(NullAddress, HeroCategory, next_hero_id, LibStructs.SerializeHero(hero));
        m_Database.Store(NullAddress, OwnershipHeroCategory, next_hero_id, OwnershipTypes.SerializeOwnership(ownership));
        m_Database.Store(NullAddress, GlobalCategory, 0, GlobalTypes.SerializeGlobal(global));

        divProfit(valuePrice);

        BuyStockHeroEvent(target, stock_id, next_hero_id);


    }

    function divProfit(uint _value) internal{

        uint256 profit_funds = uint256(m_Database.Load(bitGuildAddress, WithdrawalFundsCategory, 0));
        profit_funds = profit_funds.add(_value.div(10).mul(3)); 
        m_Database.Store(bitGuildAddress, WithdrawalFundsCategory, 0, bytes32(profit_funds));

        profit_funds = uint256(m_Database.Load(NullAddress, ProfitFundsCategory, 0));
        profit_funds = profit_funds.add(_value.div(10).mul(7)); 
        m_Database.Store(NullAddress, ProfitFundsCategory, 0, bytes32(profit_funds));
        m_Database.transfer(_value);
    }

    function GetTimeNow() view public returns (uint256){
               return now;
    }
    
    function GetInventoryHeroCount(address target) view public returns (uint256){
        require(target != address(0));

        uint256 inventory_count = uint256(m_Database.Load(target, InventoryHeroCategory, 0));

        return inventory_count;
    }
    function GetInventoryHero(address target, uint256 start_index) view public returns (uint32[8] hero_ids){
        require(target != address(0));

        uint256 inventory_count = GetInventoryHeroCount(target);

        uint256 end = start_index.add(8);
        if (end > inventory_count)
            end = inventory_count;

        for (uint256 i = start_index; i < end; i++)
        {
            hero_ids[i - start_index] = uint32(uint256(m_Database.Load(target, InventoryHeroCategory, i.add(1) )));
        }
    }
    function buyHero(LibStructs.StockHero prehero,uint16 stock_id,uint8 rarity) internal returns(LibStructs.Hero hero){

        var mainStats = generateHeroStats(prehero,rarity);
        hero = assembleHero(mainStats,rarity,stock_id,1,0);
        return hero;

    }
    function assembleHero(uint16[5] _mainStats,uint8 _rarity,uint16 stock_id,uint8 lvl,uint16 xp) private pure returns(LibStructs.Hero){
        uint16 stockID = stock_id;
        uint8 rarity= _rarity;
        uint16 hp= _mainStats[0];  
        uint16 atk= _mainStats[1];
        uint16 def= _mainStats[2];
        uint16 agi= _mainStats[3];
        uint16 intel= _mainStats[4];
        uint16 cHp= _mainStats[0];  

        return LibStructs.Hero(stockID,rarity,hp,atk,def,agi,intel,cHp,0,lvl,xp);
    }

    function generateHeroStats(LibStructs.StockHero prehero,uint8 rarity) private view returns(uint16[5] ){

        uint32  goodPoints = 0;
        uint32  normalPoints = 0;
        uint8 i = 0;
        uint16[5] memory arrayStartingStat;
        i = i.add(1);
        uint32 points = prehero.stars.add(2).add(rarity);

        uint8[2] memory mainStats = [prehero.mainOnePosition,prehero.mainTwoPosition]; 

        goodPoints = points;
        normalPoints = 8;
        uint16[5] memory arr = [uint16(1),uint16(1),uint16(1),uint16(1),uint16(1)];  
        arrayStartingStat = spreadStats(mainStats,arr,goodPoints,normalPoints,i);

        return arrayStartingStat;

    }
    function getRarity(uint8 i) private returns(uint8 result){

        result = uint8(m_Database.getRandom(100,i));
        if(result == 99){  
            result = 5;
        }else if( result >= 54 && result <= 79  ){  
            result = 2;
        }else if(result >= 80 && result <= 92){  
            result = 3;
        }else if(result >= 93 && result <= 98){  
            result = 4;
        }else{  
            result = 1;  
        }
        return ;
    }

    function spreadStats(uint8[2] mainStats,uint16[5]  arr,uint32 mainPoints,uint32 restPoints,uint index) private view returns(uint16[5]){
        uint32 i = 0;

        bytes32 blockx = block.blockhash(block.number.sub(1));
        uint256 _seed = uint256(sha3(blockx, m_Database.getRandom(100,uint8(i))));

        while(i < mainPoints){  

            uint8 position = uint8(( _seed / (10 ** index)) %10);
            if(position < 5){
                position = 0;
            }
            else{
                position = 1;
            }

            arr[mainStats[position]] = arr[mainStats[position]].add(1);
            i = i.add(1);
            index = index.add(1);

        }
        i=0;
        while(i < restPoints){  

            uint8 positionz = uint8(( _seed / (10 ** index)) %5);
            arr[positionz] = arr[positionz].add(1);
            i = i.add(1);
            index = index.add(1);

        }

        return arr;
    }
    function levelUp(uint32 hero_id)  public onlyOwnerOf(hero_id) returns(uint16[5] )  {

        LibStructs.Hero memory hero = LibStructs.DeserializeHero(m_Database.Load(NullAddress, HeroCategory, hero_id));
        LibStructs.StockHero memory stockhero = LibStructs.DeserializeStockHero(m_Database.Load(NullAddress, HeroStockCategory, hero.stockID));

        require(hero.xp >= hero.lvl.mul(15) && hero.lvl.add(1) < lvlCap);
        uint8  normalPoints = 8;
        uint8 i = 0;
        uint16[5] memory arrayStartingStat = [hero.hp,hero.atk,hero.def,hero.agi,hero.intel];
        i = i.add(1);
        uint8 goodPoints = stockhero.stars.add(2).add(hero.rarity);

        uint8[2] memory mainStats = [stockhero.mainOnePosition,stockhero.mainTwoPosition]; 

        arrayStartingStat = spreadStats(mainStats,arrayStartingStat,goodPoints,normalPoints,i);
        saveStats( hero_id, arrayStartingStat,hero.rarity,hero.stockID,hero.lvl.add(1),hero.xp);

        return arrayStartingStat;

    }
    function getXpRequiredByHero(uint32 hero_id) public view returns(uint){
        LibStructs.Hero memory hero = LibStructs.DeserializeHero(m_Database.Load(NullAddress, HeroCategory, hero_id));
        return hero.lvl.mul(15);
    }
    function saveStats(uint32 hero_id,uint16[5]  arrStats,uint8 rarity,uint16 stock_id,uint8 lvl,uint16 lastXp) internal{

        uint16 remainingXp = lastXp.sub(lvl.sub(1).mul(15));
        LibStructs.Hero memory hero = assembleHero(arrStats,rarity,stock_id,lvl,remainingXp);
        m_Database.Store(NullAddress, HeroCategory, hero_id, LibStructs.SerializeHero(hero));
        heroLeveledUp(msg.sender,hero_id);

    }

    event heroReceivedXp(uint32 hero_id,uint16 addedXp);
    function giveXp(uint32 hero_id,uint16 _xp) public OnlyOwner(){

        LibStructs.Hero memory hero = LibStructs.DeserializeHero(m_Database.Load(NullAddress, HeroCategory, hero_id));
        hero.xp = hero.xp.add(_xp);
        m_Database.Store(NullAddress, HeroCategory, hero_id, LibStructs.SerializeHero(hero));
        heroLeveledUp(hero_id,_xp);

    }

}


contract AbstractDatabase
{
    function() public payable;
    function ChangeOwner(address new_owner) public;
    function ChangeOwner2(address new_owner) public;
    function Store(address user, uint256 category, uint256 slot, bytes32 data) public;
    function Load(address user, uint256 category, uint256 index) public view returns (bytes32);
    function TransferFunds(address target, uint256 transfer_amount) public;
    function getRandom(uint256 upper, uint8 seed) public returns (uint256 number);
}