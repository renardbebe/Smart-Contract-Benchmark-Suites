 

 
 


pragma solidity ^0.4.0;


contract ReserveToken {

    address public tank;  
    uint256 public tankAllowance = 0;
    uint256 public tankOut = 0;
    uint256 public valueOfContract = 0;
    string public name;          
    string public symbol;        
    uint8 public decimals = 18;       

    uint256 public totalSupply;  
    uint256 public maxSupply = uint256(0) - 10;  
    uint256 public tankImposedMax = 100000000000000000000000;  
    uint256 public priceOfToken;     
    uint256 public divForSellBack = 2;  
    uint256 public divForTank = 200;  
    uint256 public divForPrice = 200;  
    uint256 public divForTransfer = 2;  
    uint256 public firstTTax = 10000;  
    uint256 public firstTTaxAmount = 10000;  
    uint256 public secondTTax = 20000;  
    uint256 public secondTTaxAmount = 20000;  
    uint256 public minTokens = 100;      
    uint256 public maxTokens = 1000;     
    uint256 public coinprice;  

     
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;



     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function ReserveToken() payable public {
        name = "Reserve Token";
         
        symbol = "RSRV";
         
        tank = msg.sender;
         
        priceOfToken = 1 szabo;
    }

    function MintTokens() public payable {
         
        address inAddress = msg.sender;
        uint256 inMsgValue = msg.value;

        if (inAddress != tank) {
            require(inMsgValue > 1000);  
            require(inMsgValue > priceOfToken * minTokens);  
            require(inMsgValue < priceOfToken * maxTokens);  
        }


         
        tankAllowance += (inMsgValue / divForTank);
         
        valueOfContract += (inMsgValue - (inMsgValue / divForTank));
         
        uint256 newcoins = ((inMsgValue - (inMsgValue / divForTank)) * 1 ether) / (priceOfToken);



          
        require(totalSupply + newcoins < maxSupply);
         
        require(totalSupply + newcoins < tankImposedMax);

        

         
        totalSupply += newcoins;
        priceOfToken += valueOfContract / (totalSupply / 1 ether) / divForPrice;
        balances[inAddress] += newcoins;
    }

    function BurnAllTokens() public {
        address inAddress = msg.sender;
        uint256 theirBalance = balances[inAddress];
         
        require(theirBalance > 0);
         
        balances[inAddress] = 0;
         
        coinprice = valueOfContract / (totalSupply / 1 ether);
         
        uint256 amountGoingOut = coinprice * (theirBalance / 1 ether);  
         
        uint256 tankAmount = (amountGoingOut / divForTank);  
        amountGoingOut = amountGoingOut - tankAmount;  
         
        tankAllowance += (tankAmount - (tankAmount / divForSellBack));  
         
        valueOfContract -= amountGoingOut + (tankAmount / divForSellBack);  
         
        msg.sender.transfer(amountGoingOut);
         
        totalSupply -= theirBalance;

    }

    function BurnTokens(uint256 _amount) public {
        address inAddress = msg.sender;
        uint256 theirBalance = balances[inAddress];
         
        require(_amount <= theirBalance);
         
        balances[inAddress] -= _amount;
         
        coinprice = valueOfContract / (totalSupply / 1 ether);
         
        uint256 amountGoingOut = coinprice * (_amount / 1 ether);  
         
        uint256 tankAmount = (amountGoingOut / divForTank);  
        amountGoingOut = amountGoingOut - tankAmount;  
         
        tankAllowance += (tankAmount - (tankAmount / divForSellBack));  
         
        valueOfContract -= amountGoingOut + (tankAmount / divForSellBack);  
         
        msg.sender.transfer(amountGoingOut);
         
        totalSupply -= _amount;

    }

    function CurrentCoinPrice() view public returns (uint256) {
        uint256 amountGoingOut = valueOfContract / (totalSupply / 1 ether);
         
        uint256 tankAmount = (amountGoingOut / divForTank);  
        return amountGoingOut - tankAmount;  
    }


    function TankWithdrawSome(uint256 _amount) public {
        address inAddress = msg.sender;
        require(inAddress == tank);
         

         
        if (tankAllowance < valueOfContract) {
            require(_amount <= tankAllowance - tankOut);
        }

         

        tankOut += _amount;
         
        tank.transfer(_amount);
         
    }

     
    function TankWithdrawAll() public {
        address inAddress = msg.sender;
        require(inAddress == tank);
         

         
        if (tankAllowance < valueOfContract) {
            require(tankAllowance - tankOut > 0);  
        }

         

        tankOut += tankAllowance - tankOut;  
         
        tank.transfer(tankAllowance - tankOut);
         
    }





    function TankDeposit() payable public {
        address inAddress = msg.sender;
        uint256 inValue = msg.value;

        require(inAddress == tank);
         

        if (inValue < tankOut) {
            tankOut -= inValue;
             
        }
        else
        {
             
            valueOfContract += (inValue - tankOut) * 1 ether;
             
            tankOut = 0;

        }
    }


     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFee(uint256 _amount) view internal returns (uint256){
         
        if (_amount > secondTTaxAmount)
            return secondTTax;

        if (_amount > firstTTaxAmount)
            return firstTTax;
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
         
        uint256 fromBalance = balances[msg.sender];
        uint256 toBalance = balances[_to];
        uint256 tFee = transferFee(_amount);


         
        require(fromBalance >= _amount + tFee);
         
        require(_amount > 0);
         
        require(toBalance + _amount > toBalance);

        balances[msg.sender] -= _amount + tFee;
        balances[_to] += _amount;
        balances[tank] += tFee / divForTransfer;
        totalSupply -= tFee - (tFee / divForTransfer);

        emit Transfer(msg.sender, _to, _amount);
         

        return true;
    }




     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        uint256 fromBalance = balances[_from];   
        uint256 toBalance = balances[_to];       
        uint256 tFee = transferFee(_amount);     

         
        require(fromBalance >= _amount + tFee);
         
        require(allowed[_from][msg.sender] >= _amount + tFee);
         
        require(_amount > 0);
         
        require(toBalance + _amount > toBalance);

         
        balances[_from] -= _amount + tFee;
        allowed[_from][msg.sender] -= _amount + tFee;
        balances[_to] += _amount;
        balances[tank] += tFee / divForTransfer;
        totalSupply -= tFee - (tFee / divForTransfer);
        emit Transfer(_from, _to, _amount);

        return true;
    }



     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }



    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     function GrabUnallocatedValue() public {
         address inAddress = msg.sender;
         require(inAddress == tank);
          
          
         address walletaddress = this;
         if (walletaddress.balance * 1 ether > valueOfContract) {
            tank.transfer(walletaddress.balance - (valueOfContract / 1 ether));
         }
    }


    function TankTransfer(address _NewTank) public {
        address inAddress = msg.sender;
        require(inAddress == tank);
        tank = _NewTank;
    }

    function SettankImposedMax(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         tankImposedMax = _input;
    }

    function SetdivForSellBack(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForSellBack = _input;
    }

    function SetdivForTank(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForTank = _input;
    }

    function SetdivForPrice(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForPrice = _input;
    }

    function SetfirstTTax(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         firstTTax = _input;
    }

    function SetfirstTTaxAmount(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         firstTTaxAmount = _input;
    }

    function SetsecondTTax(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         secondTTax = _input;
    }

    function SetsecondTTaxAmount(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         secondTTaxAmount = _input;
    }

    function SetminTokens(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         minTokens = _input;
    }

    function SetmaxTokens(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         maxTokens = _input;
    }

    function SetdivForTransfer(uint256 _input) public {
         address inAddress = msg.sender;
         require(inAddress == tank);
         divForTransfer = _input;
    }



}