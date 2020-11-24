 

 

pragma solidity >=0.5.0 <0.6.0;

contract EthPixel {

     
     
    struct Pixel {                                   
        address owner;                               
        uint8   color;                               
        uint88  price;                               
    }
    
     
    struct Player {
        uint32 holding;                              
        uint96 sub_total;
        uint96 one_pixel_value_offset;
    }
    
    mapping(uint    => Pixel)  canvas;               
    mapping(address => Player) players;              
    
     
    uint32 constant width                = 400;              
    uint32 constant height               = 400;              
    uint88 constant new_price            =   0.0005 ether;   
    uint96 constant increment_percentage = 135;              
    uint96 constant pot_percentage       =  40;              
    uint96 constant payout_percentage    =  50;              
    uint96 constant revenue_percentage   =  80;              
    uint96 constant dev_percentage       =   2;              
    uint32 constant time_increment       =  60 seconds;      
    
     
    uint32 constant playing_field = width * height;
    
     
    uint32 public expiration;                        
    uint32 public sold_pixels;                       
    uint96 public pot;                               
    uint96 public payout;                            
    
    uint96 public revenues;                          
    uint96 public one_pixel_value;
    uint96 public withdrawals;                       
    
    bool last_buyer_cashed_out = false;
    bool biggest_holder_cashed_out = false;
    
    address payable public last_buyer;               
    address payable public biggest_holder;           
    
    address payable dev_account;
    
     
    event PixelBought(uint _index, address _owner, uint _color, uint _price);
    event NewConditions(uint _expiration, uint _sold_pixels, uint _pot, uint _payout, address _last_buyer, uint32 _totalBuy, address _sender);
     
    constructor() public {
        require(pot_percentage + payout_percentage <= 100, "revert1");
        require(increment_percentage >= 100, "revert2");
        require(revenue_percentage * increment_percentage >= 10000, "revert3");
        require(revenue_percentage + dev_percentage <= 100, "revert4");
        
        dev_account = msg.sender;
        expiration = uint32(now) + 1 days;
        biggest_holder = dev_account;
    }
     
     
    function isGameGoing() external view returns (bool _gameIsGoing) {
        return (now < expiration);
    }
    
     
    function getPixel(uint _index) external view returns (address owner, uint color, uint price) {
        if (canvas[_index].price == 0) return (address(0),           0,                    new_price);
        else                           return (canvas[_index].owner, canvas[_index].color, canvas[_index].price);
    }
    
     
    function getPixel(uint _indexFrom, uint _len) external view returns (address[] memory owner, uint[] memory color, uint[] memory price) {
        address[] memory _owner = new address[](_len);
        uint[] memory _color = new uint[](_len);
        uint[] memory _price = new uint[](_len);
        uint counter = 0;
        uint iLen = _indexFrom + _len;
        for (uint i = _indexFrom; i < iLen; i++) {
            if (canvas[i].price == 0) {_owner[counter] = address(0);      _color[counter] = 0;               _price[counter] = new_price;      } 
            else                      {_owner[counter] = canvas[i].owner; _color[counter] = canvas[i].color; _price[counter] = canvas[i].price;}
            counter++; 
        }
        return (_owner, _color, _price);
    }
    
     
    function getColor() external view returns (uint[] memory color) {
        uint[] memory _color = new uint[](playing_field / 32);
        uint temp;
        for (uint i = 0; i < (playing_field / 32); i++) {
            temp = 0;
            for (uint j = 0; j < 32; j++) {
                temp += uint(canvas[i * 32 + j].color) << (8 * j);
            }
            _color[i] = temp;
        }
        return (_color);
    }
    
     
    function getPriceOwner(uint _index, uint _len) external view returns (uint[] memory) {
        uint[] memory result = new uint[](_len);
        for (uint i = 0; i < _len; i++) {
            if (canvas[_index + i].price == 0) result[i] = new_price;
            else result[i] = (uint256(canvas[_index + i].owner) << 96) + canvas[_index + i].price;
        }
        return result;
    }
    
     
    function getHoldingOf(address _address) external view returns(uint32 _holding) {
        return players[_address].holding;
    }
    
     
    function getBalanceOf(address _address) external view returns(uint96 _value) {
        require(_address == msg.sender, "revert5");
        return players[_address].sub_total + players[_address].holding * (one_pixel_value - players[_address].one_pixel_value_offset);
    }
     
     
    function putPixel(uint _index, address _owner, uint8 _color, uint88 _price) private {
        canvas[_index].owner = _owner;
        canvas[_index].color = _color;
        canvas[_index].price = _price;
    }
    
     
    function putPlayer(address _player, uint32 _holding, uint96 _sub_total, uint96 _one_pixel_value_offset) private {
        players[_player].holding                = _holding;
        players[_player].sub_total              = _sub_total;
        players[_player].one_pixel_value_offset = _one_pixel_value_offset;
    }
    
    function putStateVariables(
        uint32 _expiration,
        uint32 _sold_pixels,
        uint96 _pot,
        uint96 _payout,
        uint96 _revenues,
        uint96 _one_pixel_value
    )
        private
    {
        expiration      = _expiration;
        sold_pixels     = _sold_pixels;
        pot             = _pot;
        payout          = _payout;
        revenues        = _revenues;
        one_pixel_value = _one_pixel_value;
    }
    
    function balanceOf(address _address) private view returns(uint96 _value) {
        return players[_address].sub_total + players[_address].holding * (one_pixel_value - players[_address].one_pixel_value_offset);
    }
     
     
    function buy(uint[] memory _index, uint8[] memory _color, uint[] memory _price, address _referrar) public payable {
        require(now < expiration, "revert8");                    
        require(_index.length == _color.length, "revert9");
        require(_index.length == _price.length, "revert10");
        
        uint96 spendETH         = 0;
        uint32 f_sold_pixels    = 0;
        uint32 f_holding        = 0;
        uint96 f_sub_total      = 0;
        uint96 f_revenues       = 0;
        uint96 increase         = 0;
        uint32 totalBuy         = 0;
        uint96 pixel_price;

        for(uint i = 0; i < _index.length; i++) {
            if(_index[i] >= playing_field) continue;             
            
            address previous_owner = canvas[_index[i]].owner;
             
            if(previous_owner == address(0)) {
                pixel_price = new_price;
                if(pixel_price != _price[i]) continue;
                if((spendETH + pixel_price) > msg.value) continue;
                spendETH += pixel_price;
                
                increase += pixel_price;
                f_sold_pixels++;
                f_holding++;
            }
            
             
            else {
                pixel_price = canvas[_index[i]].price;
                if(pixel_price != _price[i]) continue;
                if((spendETH + pixel_price) > msg.value) continue;
                spendETH += pixel_price;
                
                uint96 to_previous_owner = (pixel_price * revenue_percentage) / 100;
                f_revenues += to_previous_owner;
                increase += pixel_price - to_previous_owner - ((pixel_price * dev_percentage) / 100);
                
                 
                if(previous_owner != msg.sender) {
                    f_holding++;
                    putPlayer(previous_owner, players[previous_owner].holding - 1, balanceOf(previous_owner) + to_previous_owner, one_pixel_value);
                }
                 
                else f_sub_total += to_previous_owner;
            }
            
            totalBuy++;
            pixel_price = (pixel_price * increment_percentage) / 100;
            putPixel(_index[i], msg.sender, _color[i], uint88(pixel_price));
            emit PixelBought(_index[i], msg.sender, _color[i], pixel_price);
        }
        
         
        if(spendETH < uint96(msg.value)) {
            f_sub_total += uint96(msg.value) - spendETH;    
        }
        putPlayer(msg.sender, players[msg.sender].holding + f_holding, balanceOf(msg.sender) + f_sub_total, one_pixel_value);
        
        if(totalBuy != 0) {
             
            uint96 f_payout = (increase * payout_percentage) / 100;
            uint96 f_pot;
            if((players[_referrar].holding > 0) && (_referrar != msg.sender)) {
                f_pot = (increase * pot_percentage) / 100;
                uint96 referral_bonus = increase - f_payout - f_pot;
                 
                f_revenues += referral_bonus;
                players[_referrar].sub_total += referral_bonus;
            }
            else f_pot = increase - f_payout;              
            
             
            uint96 f_one_pixel_value = f_payout / (sold_pixels + f_sold_pixels);
            
             
            uint32 maxExpiration = uint32(now) + 1 days;
            uint32 f_expiration = expiration + (totalBuy * time_increment);
            if (f_expiration > maxExpiration) f_expiration = maxExpiration;
            
             
            f_sold_pixels += sold_pixels;
            f_pot += pot;
            f_payout += payout;
            f_revenues += revenues;
            f_one_pixel_value += one_pixel_value;
            putStateVariables(
                f_expiration,
                f_sold_pixels,
                f_pot,
                f_payout,
                f_revenues,
                f_one_pixel_value
            );
            
            if(last_buyer != msg.sender) last_buyer = msg.sender;
        }
        
        emit NewConditions(expiration, sold_pixels, pot, payout, last_buyer, totalBuy, msg.sender);
    }
     
    modifier notFinalDeadline() {
        require(now < expiration + 365 days, "revert9");
        _;
    }
    
     
    function withdraw() public notFinalDeadline {
        uint96 amount = balanceOf(msg.sender);
        putPlayer(msg.sender, players[msg.sender].holding, 0, one_pixel_value);
        withdrawals += amount;
        msg.sender.transfer(amount);
    }
    
     
    function dev_withdrawal(uint96 _amount) public {
        require(msg.sender == dev_account);
        
        uint ether_paid = address(this).balance + withdrawals;
        uint ether_used = payout + pot + revenues;
        uint max = ether_paid - ether_used;
        require(_amount <= max, "revert10");
        dev_account.transfer(_amount);
    }
    
    function final_dev_withdrawal() public {
        require(now > expiration + 365 days, "revert11");
        require(msg.sender == dev_account);
        dev_account.transfer(address(this).balance);
    }
     
     
    function update_biggest_holder(address payable _address) public notFinalDeadline returns(address _biggest_holder) {
        require(biggest_holder != address(0));
        if (players[_address].holding > players[biggest_holder].holding) biggest_holder = _address;
        return biggest_holder;
    }
    
     
    function award_last_buyer() public notFinalDeadline {
        require(now > expiration);
        require(last_buyer_cashed_out == false);
        
        last_buyer_cashed_out = true;
        uint96 half_award = pot / 2;
        withdrawals += half_award;
        last_buyer.transfer(half_award);
    }
    
    function award_biggest_holder() public notFinalDeadline {
         
         
        require(now > expiration + 7 days);
        require(biggest_holder_cashed_out == false);

        biggest_holder_cashed_out = true;
        uint96 half_award = pot / 2;
        withdrawals += half_award;
        biggest_holder.transfer(half_award);
    }
}