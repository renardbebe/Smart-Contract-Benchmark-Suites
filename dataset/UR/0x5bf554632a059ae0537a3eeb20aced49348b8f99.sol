 

 

pragma solidity ^0.4.17;

 
 
contract ERC20Interface {

     
    string public constant symbol = "TBA";

     
    string public constant name ="TBA";

     
    uint8 public constant decimals = 18;

     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract ERC20Token is ERC20Interface{

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool) {
        if (balances[msg.sender] >= _amount && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

}


 
contract SoulToken is ERC20Token{

     
    string public constant symbol = "SOUL";

     
    string public constant name = "Soul Napkins";

     
    uint8 public constant decimals = 6;

     
    uint256 public constant unit = 1000000;

     
    uint8 public constant obol = 10;

     
    uint256 public constant napkinPrice = 10 finney / unit;

     
     
    uint256 constant totalSupply_ = 144000 * unit;

     
    mapping(address => string) reasons;

     
    mapping(address => uint256) soulPrices;

     
    mapping(address => address) ownedBy;

     
    mapping(address => uint256) soulsOwned;

     
    mapping(uint256 => address) soulBook;

     
    address public owner;

     
    address public charonsBoat;

     
    uint256 public bookingFee;

     
    uint256 public soulsForSale;

     
    uint256 public soulsSold;

     
    uint256 public totalObol;

     
    event SoulTransfer(address indexed _from, address indexed _to);

    function SoulToken() public{
        owner = msg.sender;
        charonsBoat = msg.sender;
         
        bookingFee = 13 finney;
        soulsForSale = 0;
        soulsSold = 0;
        totalObol = 0;
         
        balances[this] = totalSupply_;
         
        payOutNapkins(1111 * unit);
    }

     
    function () public payable {
        uint256 amount;
        uint256 checkedAmount;
         
        amount = msg.value / napkinPrice;
        checkedAmount = checkAmount(amount);
         
         
        require(amount == checkedAmount);
         
        payCharon(msg.value);
         
        payOutNapkins(checkedAmount);
    }

     
    function changeBookingFee(uint256 fee) public {
        require(msg.sender == owner);
        bookingFee = fee;
    }

     
    function changeBoat(address newBoat) public{
        require(msg.sender == owner);
        charonsBoat = newBoat;
    }

     
    function totalSupply() public constant returns (uint256){
        return totalSupply_;
    }

     
    function soldSoulBecause(address noSoulMate) public constant returns(string){
        return reasons[noSoulMate];
    }

     
    function soulIsOwnedBy(address noSoulMate) public constant returns(address){
        return ownedBy[noSoulMate];
    }

     
    function ownsSouls(address soulOwner) public constant returns(uint256){
        return soulsOwned[soulOwner];
    }

     
    function soldSoulFor(address noSoulMate) public constant returns(uint256){
        return soulPrices[noSoulMate];
    }

     
    function soulBookPage(uint256 page) public constant returns(address){
        return soulBook[page];
    }

     
    function sellSoul(string reason, uint256 price) public payable{
        uint256 charonsObol;
        string storage has_reason = reasons[msg.sender];

         
        require(bytes(reason).length > 0);

         
        require(msg.value >= bookingFee);

         
        charonsObol = price / obol;
        require(charonsObol > 0);

         
        require(bytes(has_reason).length == 0);
        require(soulPrices[msg.sender] == 0);
        require(ownedBy[msg.sender] == address(0));

         
        payCharon(msg.value);

         
        reasons[msg.sender] = reason;
         
        soulPrices[msg.sender] = price;
         
        soulBook[soulsForSale + soulsSold] = msg.sender;
        soulsForSale += 1;
    }

     
    function buySoul(address noSoulMate) public payable returns(uint256 amount){
        uint256 charonsObol;
        uint256 price;

         
        require(ownedBy[noSoulMate] == address(0));
         
        price = soulPrices[noSoulMate];
         
        require(price > 0);
        require(bytes(reasons[noSoulMate]).length > 0);
         
        require(msg.value >= price);
        charonsObol = msg.value / obol;

         
        require(soulsOwned[msg.sender] + 1 > soulsOwned[msg.sender]);

         
        payCharon(charonsObol);
         
        noSoulMate.transfer(msg.value - charonsObol);

         
        soulsForSale -= 1;
        soulsSold += 1;
         
        soulsOwned[msg.sender] += 1;
        ownedBy[noSoulMate] = msg.sender;
         
        SoulTransfer(noSoulMate, msg.sender);

         
        amount = charonsObol / napkinPrice + unit;
        amount = checkAmount(amount);
        if (amount > 0){
             
            payOutNapkins(amount);
        }

        return amount;
    }

     
    function transferSoul(address _to, address noSoulMate) public payable{
        uint256 charonsObol;

         
        require(ownedBy[noSoulMate] == msg.sender);
        require(soulsOwned[_to] + 1 > soulsOwned[_to]);
         
        charonsObol = soulPrices[noSoulMate] / obol;
        require(msg.value >= charonsObol);
         
        payCharon(msg.value);
         
        soulsOwned[msg.sender] -= 1;
        soulsOwned[_to] += 1;
        ownedBy[noSoulMate] = _to;

         
        SoulTransfer(msg.sender, _to);
    }

     
    function payCharon(uint256 obolValue) internal{
        totalObol += obolValue;
        charonsBoat.transfer(obolValue);
    }

     
    function checkAmount(uint256 amount) internal constant returns(uint256 checkedAmount){

        if (amount > balances[this]){
            checkedAmount = balances[this];
        } else {
            checkedAmount = amount;
        }

        return checkedAmount;
    }

     
    function payOutNapkins(uint256 amount) internal{
         
        require(amount > 0);
         
        require(amount <= balances[this]);

         
        balances[this] -= amount;
        balances[msg.sender] += amount;
         
        Transfer(this, msg.sender, amount);
    }

}