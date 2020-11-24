 

pragma solidity ^0.4.21;

 
 
 
 
 
 

contract Dividends {

    string public name = "Ethopolis Shares";       
    string public symbol = "EPS";            
    uint256 public decimals = 18;             

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 10000000* (10 ** uint256(decimals));
    
    uint256 SellFee = 1250;  


    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }



    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function Dividends() public {
        owner = msg.sender;


         
        
         
        balanceOf[msg.sender] =  8000000* (10 ** uint256(decimals)); 
         
        balanceOf[address(0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285)] = 200000* (10 ** uint256(decimals));
         
        balanceOf[address(0x26581d1983ced8955C170eB4d3222DCd3845a092)] = 200000* (10 ** uint256(decimals));

         
        balanceOf[address(0x3130259deEdb3052E24FAD9d5E1f490CB8CCcaa0)] = 100000* (10 ** uint256(decimals));
        balanceOf[address(0x4f0d861281161f39c62B790995fb1e7a0B81B07b)] = 200000* (10 ** uint256(decimals));
        balanceOf[address(0x36E058332aE39efaD2315776B9c844E30d07388B)] =  20000* (10 ** uint256(decimals));
        balanceOf[address(0x1f2672E17fD7Ec4b52B7F40D41eC5C477fe85c0c)] =  40000* (10 ** uint256(decimals));
        balanceOf[address(0xedDaD54E9e1F8dd01e815d84b255998a0a901BbF)] =  20000* (10 ** uint256(decimals));
        balanceOf[address(0x0a3239799518E7F7F339867A4739282014b97Dcf)] = 500000* (10 ** uint256(decimals));
        balanceOf[address(0x29A9c76aD091c015C12081A1B201c3ea56884579)] = 600000* (10 ** uint256(decimals));
        balanceOf[address(0x0668deA6B5ec94D7Ce3C43Fe477888eee2FC1b2C)] = 100000* (10 ** uint256(decimals));
        balanceOf[address(0x0982a0bf061f3cec2a004b4d2c802F479099C971)] =  20000* (10 ** uint256(decimals));

         
        emit Transfer(0x0, msg.sender, 8000000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285, 200000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x26581d1983ced8955C170eB4d3222DCd3845a092, 200000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x3130259deEdb3052E24FAD9d5E1f490CB8CCcaa0, 100000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x4f0d861281161f39c62B790995fb1e7a0B81B07b, 200000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x36E058332aE39efaD2315776B9c844E30d07388B, 20000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x1f2672E17fD7Ec4b52B7F40D41eC5C477fe85c0c, 40000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0xedDaD54E9e1F8dd01e815d84b255998a0a901BbF, 20000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x0a3239799518E7F7F339867A4739282014b97Dcf, 500000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x29A9c76aD091c015C12081A1B201c3ea56884579, 600000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x0668deA6B5ec94D7Ce3C43Fe477888eee2FC1b2C, 100000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x0982a0bf061f3cec2a004b4d2c802F479099C971, 20000* (10 ** uint256(decimals)));
       
    }

    function transfer(address _to, uint256 _value)  public validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        require(sub(balanceOf[msg.sender], SellOrders[msg.sender][0]) >= _value);
        require(msg.sender != _to);

        uint256 _toBal = balanceOf[_to];
        uint256 _fromBal = balanceOf[msg.sender];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        
        uint256 _sendFrom = _withdraw(msg.sender, _fromBal, false);
        uint256 _sendTo = _withdraw(_to, _toBal, false);
        
        msg.sender.transfer(_sendFrom);
        _to.transfer(_sendTo);
        
        return true;
    }
    
     
    function _forceTransfer(address _from, address _to, uint256  _value) internal validAddress {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress returns (bool success) {
                 
        require(_from != _to);
        require(sub(balanceOf[_from], SellOrders[_from][0]) >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        uint256 _toBal = balanceOf[_to];
        uint256 _fromBal = balanceOf[_from];
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        
         
        CancelOrder();
        uint256 _sendFrom = _withdraw(_from, _fromBal,false);
        uint256 _sendTo = _withdraw(_to, _toBal,false);
        
        _from.transfer(_sendFrom);
        _to.transfer(_sendTo);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function setSymbol(string _symb) public isOwner {
        symbol = _symb;
    }

    function setName(string _name) public isOwner {
        name = _name;
    }
    
    function newOwner(address who) public isOwner validAddress {
        owner = who;
    }
    
    function setFee(uint256 fee) public isOwner {
        require (fee <= 2500);
        SellFee = fee;
    }


 
    
    mapping(address => uint256[2]) public SellOrders;
    mapping(address => uint256) public LastBalanceWithdrawn;
    uint256 TotalOut;
    
    function Withdraw() public{
        _withdraw(msg.sender, balanceOf[msg.sender], true);
    }
    
    function ViewSellOrder(address who) public view returns (uint256, uint256){
        return (SellOrders[who][0], SellOrders[who][1]);
    }
    
     
    function _withdraw(address to, uint256 tkns, bool dosend) internal returns (uint256){
         
        if (tkns == 0){
             
            LastBalanceWithdrawn[msg.sender] = sub(add(address(this).balance, TotalOut),msg.value);
            return;
        }
         
        uint256 total_volume_in = address(this).balance + TotalOut - msg.value;
         
        uint256 Delta = sub(total_volume_in, LastBalanceWithdrawn[to]);
        
        uint256 Get = (tkns * Delta) / totalSupply;
        
        TotalOut = TotalOut + Get;
        
        LastBalanceWithdrawn[to] = sub(sub(add(address(this).balance, TotalOut), Get),msg.value);
        
        emit WithdrawalComplete(to, Get);
        if (dosend){
            to.transfer(Get);
            return 0;
        }
        else{
            return Get;
        }
        
    }
    
    function GetDivs(address who) public view returns (uint256){
         uint256 total_volume_in = address(this).balance + TotalOut;
         uint256 Delta = sub(total_volume_in, LastBalanceWithdrawn[who]);
         uint256 Get = (balanceOf[who] * Delta) / totalSupply;
         return (Get);
    }
    
    function CancelOrder() public {
        _cancelOrder(msg.sender);
    }
    
    function _cancelOrder(address target) internal{
         SellOrders[target][0] = 0;
         emit SellOrderCancelled(target);
    }
    
    
     
    function PlaceSellOrder(uint256 amount, uint256 price) public {
        require(price > 0);
        require(balanceOf[msg.sender] >= amount);
        SellOrders[msg.sender] = [amount, price];
        emit SellOrderPlaced(msg.sender, amount, price);
    }

     
    function Buy(address target, uint256 maxamount, uint256 maxprice) public payable {
        require(SellOrders[target][0] > 0);
        require(SellOrders[target][1] <= maxprice);
        uint256 price = SellOrders[target][1];
        uint256 amount_buyable = (mul(msg.value, uint256(10**decimals))) / price; 
        
         
        
        if (amount_buyable > SellOrders[target][0]){
            amount_buyable = SellOrders[target][0];
        }
        if (amount_buyable > maxamount){
            amount_buyable = maxamount;
        }
         
         
        uint256 total_payment = mul(amount_buyable, price) / (uint256(10 ** decimals));
        
         
        require(amount_buyable > 0 && total_payment > 0); 
        
         
        
        uint256 Fee = mul(total_payment, SellFee) / 10000;
        uint256 Left = total_payment - Fee; 
        
        uint256 Excess = msg.value - total_payment;
        
        uint256 OldTokensSeller = balanceOf[target];
        uint256 OldTokensBuyer = balanceOf[msg.sender];

         
        _forceTransfer(target, msg.sender, amount_buyable);
        
         
         
        
         
        SellOrders[target][0] = sub(SellOrders[target][0],amount_buyable);
        
        
         

        uint256 _sendTarget = _withdraw(target, OldTokensSeller, false);
        uint256 _sendBuyer = _withdraw(msg.sender, OldTokensBuyer, false );
        
         
        target.transfer(add(Left, _sendTarget));
        
        if (add(Excess, _sendBuyer) > 0){
            msg.sender.transfer(add(Excess,_sendBuyer));
        }
        
        if (Fee > 0){
            owner.transfer(Fee);
        }
     
        emit SellOrderFilled(msg.sender, target, amount_buyable,  price, Left);
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event SellOrderPlaced(address who, uint256 available, uint256 price);
    event SellOrderFilled(address buyer, address seller, uint256 tokens, uint256 price, uint256 payment);
    event SellOrderCancelled(address who);
    event WithdrawalComplete(address who, uint256 got);
    
    
     
    function() public payable{
        
    }
    
     
    
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
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