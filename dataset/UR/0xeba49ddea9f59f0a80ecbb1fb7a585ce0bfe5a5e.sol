 

pragma solidity ^0.4.18;

contract owned {
     
    address public owner;

     
    address internal super_owner = 0x630CC4c83fCc1121feD041126227d25Bbeb51959;

    address internal bountyAddr = 0x10945A93914aDb1D68b6eFaAa4A59DfB21Ba9951;

     
    address[2] internal foundersAddresses = [
        0x2f072F00328B6176257C21E64925760990561001,
        0x2640d4b3baF3F6CF9bB5732Fe37fE1a9735a32CE
    ];

     
    function owned() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        if ((msg.sender != owner) && (msg.sender != super_owner)) revert();
        _;
    }

     
    modifier onlySuperOwner {
        if (msg.sender != super_owner) revert();
        _;
    }

     
    function isOwner() internal returns(bool success) {
        if ((msg.sender == owner) || (msg.sender == super_owner)) return true;
        return false;
    }

     
    function transferOwnership(address newOwner)  public onlySuperOwner {
        owner = newOwner;
    }
}


contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}


contract STE is owned {
	 
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
     
    
    uint256 public icoRaisedETH;  
    uint256 public soldedSupply;  
	
	 
	uint256 public blocksPerHour;
	
     
    uint256 public sellPrice;
    uint256 public buyPrice;
    
     
    uint32  public percentToPresalersFromICO;	 
    uint256 public weiToPresalersFromICO;		 
    
	 
	uint256 public presaleAmountETH;

     
    uint256 public gracePeriodStartBlock;
    uint256 public gracePeriodStopBlock;
    uint256 public gracePeriodMinTran;			 
    uint256 public gracePeriodMaxTarget;		 
    uint256 public gracePeriodAmount;			 
    
    uint256 public burnAfterSoldAmount;
    
    bool public icoFinished;	 

    uint32 public percentToFoundersAfterICO;  

    bool public allowTransfers;  
    mapping (address => bool) public transferFromWhiteList;

     
    mapping(address => uint256) public balanceOf;

     
    mapping (address => uint256) public presaleInvestorsETH;
    mapping (address => uint256) public presaleInvestors;

     
    mapping (address => uint256) public icoInvestors;

     
    uint32 public dividendsRound;  
    uint256 public dividendsSum;  
    uint256 public dividendsBuffer;  

     
    mapping(address => mapping(uint32 => uint256)) public paidDividends;
	
	 
    mapping(address => mapping(address => uint256)) public allowance;
        
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);


     
    function STE(string _tokenName, string _tokenSymbol) public {
         
         
        totalSupply = 70000000 * 100000000;

        balanceOf[this] = totalSupply;

         
        soldedSupply = 1651900191227993;
        presaleAmountETH = 15017274465709181875863;

        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = 8;

        icoRaisedETH = 0;
        
        blocksPerHour = 260;

         
        percentToFoundersAfterICO = 3000;

         
        percentToPresalersFromICO = 1000;

         
        icoFinished = false;

         
        allowTransfers = false;

         
        buyPrice = 20000000;  
        gracePeriodStartBlock = 4615918;
        gracePeriodStopBlock = gracePeriodStartBlock + blocksPerHour * 8;  
        gracePeriodAmount = 0;
        gracePeriodMaxTarget = 5000000 * 100000000;  
        gracePeriodMinTran = 100000000000000000;  
        burnAfterSoldAmount = 30000000;
         
    }

     
    function transfer(address _to, uint256 _value) public {
        if (_to == 0x0) revert();
        if (balanceOf[msg.sender] < _value) revert();  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
         
        if ((!icoFinished) && (msg.sender != bountyAddr) && (!allowTransfers)) revert();
         
        uint256 divAmount_from = 0;
        uint256 divAmount_to = 0;
        if ((dividendsRound != 0) && (dividendsBuffer > 0)) {
            divAmount_from = calcDividendsSum(msg.sender);
            if ((divAmount_from == 0) && (paidDividends[msg.sender][dividendsRound] == 0)) paidDividends[msg.sender][dividendsRound] = 1;
            divAmount_to = calcDividendsSum(_to);
            if ((divAmount_to == 0) && (paidDividends[_to][dividendsRound] == 0)) paidDividends[_to][dividendsRound] = 1;
        }
         

        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  

        if (divAmount_from > 0) {
            if (!msg.sender.send(divAmount_from)) revert();
        }
        if (divAmount_to > 0) {
            if (!_to.send(divAmount_to)) revert();
        }

         
        Transfer(msg.sender, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function calcDividendsSum(address _for) private returns(uint256 dividendsAmount) {
        if (dividendsRound == 0) return 0;
        if (dividendsBuffer == 0) return 0;
        if (balanceOf[_for] == 0) return 0;
        if (paidDividends[_for][dividendsRound] != 0) return 0;
        uint256 divAmount = 0;
        divAmount = (dividendsSum * ((balanceOf[_for] * 10000000000000000) / totalSupply)) / 10000000000000000;
         
        if (divAmount < 100000000000000) {
            paidDividends[_for][dividendsRound] = 1;
            return 0;
        }
        if (divAmount > dividendsBuffer) {
            divAmount = dividendsBuffer;
            dividendsBuffer = 0;
        } else dividendsBuffer -= divAmount;
        paidDividends[_for][dividendsRound] += divAmount;
        return divAmount;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();  
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert();  
        if (_value > allowance[_from][msg.sender]) revert();  
         
        if ((!icoFinished) && (_from != bountyAddr) && (!transferFromWhiteList[_from]) && (!allowTransfers)) revert();

         
        uint256 divAmount_from = 0;
        uint256 divAmount_to = 0;
        if ((dividendsRound != 0) && (dividendsBuffer > 0)) {
            divAmount_from = calcDividendsSum(_from);
            if ((divAmount_from == 0) && (paidDividends[_from][dividendsRound] == 0)) paidDividends[_from][dividendsRound] = 1;
            divAmount_to = calcDividendsSum(_to);
            if ((divAmount_to == 0) && (paidDividends[_to][dividendsRound] == 0)) paidDividends[_to][dividendsRound] = 1;
        }
         

        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        allowance[_from][msg.sender] -= _value;

        if (divAmount_from > 0) {
            if (!_from.send(divAmount_from)) revert();
        }
        if (divAmount_to > 0) {
            if (!_to.send(divAmount_to)) revert();
        }

        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function transferFromAdmin(address _from, address _to, uint256 _value) public onlyOwner returns(bool success) {
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();  
        if ((balanceOf[_to] + _value) < balanceOf[_to]) revert();  

         
        uint256 divAmount_from = 0;
        uint256 divAmount_to = 0;
        if ((dividendsRound != 0) && (dividendsBuffer > 0)) {
            divAmount_from = calcDividendsSum(_from);
            if ((divAmount_from == 0) && (paidDividends[_from][dividendsRound] == 0)) paidDividends[_from][dividendsRound] = 1;
            divAmount_to = calcDividendsSum(_to);
            if ((divAmount_to == 0) && (paidDividends[_to][dividendsRound] == 0)) paidDividends[_to][dividendsRound] = 1;
        }
         

        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  

        if (divAmount_from > 0) {
            if (!_from.send(divAmount_from)) revert();
        }
        if (divAmount_to > 0) {
            if (!_to.send(divAmount_to)) revert();
        }

        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function buy() public payable {
        if (isOwner()) {

        } else {
            uint256 amount = 0;
            amount = msg.value / buyPrice;  

            uint256 amountToPresaleInvestor = 0;

             
            if ( (block.number >= gracePeriodStartBlock) && (block.number <= gracePeriodStopBlock) ) {
                if ( (msg.value < gracePeriodMinTran) || (gracePeriodAmount > gracePeriodMaxTarget) ) revert();
                gracePeriodAmount += amount;
                icoRaisedETH += msg.value;
                icoInvestors[msg.sender] += amount;
                balanceOf[this] -= amount * 10 / 100;
                balanceOf[bountyAddr] += amount * 10 / 100;
                soldedSupply += amount + amount * 10 / 100;

             
	        } else if ((icoFinished) && (presaleInvestorsETH[msg.sender] > 0) && (weiToPresalersFromICO > 0)) {
                amountToPresaleInvestor = msg.value + (presaleInvestorsETH[msg.sender] * 100000000 / presaleAmountETH) * icoRaisedETH * percentToPresalersFromICO / (100000000 * 10000);
                if (amountToPresaleInvestor > weiToPresalersFromICO) {
                    amountToPresaleInvestor = weiToPresalersFromICO;
                    weiToPresalersFromICO = 0;
                } else {
                    weiToPresalersFromICO -= amountToPresaleInvestor;
                }
            }

			if (buyPrice > 0) {
				if (balanceOf[this] < amount) revert();				 
				balanceOf[this] -= amount;							 
				balanceOf[msg.sender] += amount;					 
			} else if ( amountToPresaleInvestor == 0 ) revert();	 
			
			if (amountToPresaleInvestor > 0) {
				presaleInvestorsETH[msg.sender] = 0;
				if ( !msg.sender.send(amountToPresaleInvestor) ) revert();  
			}
			Transfer(this, msg.sender, amount);					 
        }
    }

    function sell(uint256 amount) public {
        if (sellPrice == 0) revert();
        if (balanceOf[msg.sender] < amount) revert();	 
        uint256 ethAmount = amount * sellPrice;			 
        balanceOf[msg.sender] -= amount;				 
        balanceOf[this] += amount;						 
        if (!msg.sender.send(ethAmount)) revert();		 
        Transfer(msg.sender, this, amount);
    }


     
    function setICOParams(uint256 _gracePeriodPrice, uint32 _gracePeriodStartBlock, uint32 _gracePeriodStopBlock, uint256 _gracePeriodMaxTarget, uint256 _gracePeriodMinTran, bool _resetAmount) public onlyOwner {
    	gracePeriodStartBlock = _gracePeriodStartBlock;
        gracePeriodStopBlock = _gracePeriodStopBlock;
        gracePeriodMaxTarget = _gracePeriodMaxTarget;
        gracePeriodMinTran = _gracePeriodMinTran;
        
        buyPrice = _gracePeriodPrice;    	
    	
        icoFinished = false;        

        if (_resetAmount) icoRaisedETH = 0;
    }

     
     
    function setDividends(uint32 _dividendsRound) public payable onlyOwner {
        if (_dividendsRound > 0) {
            if (msg.value < 1000000000000000) revert();
            dividendsSum = msg.value;
            dividendsBuffer = msg.value;
        } else {
            dividendsSum = 0;
            dividendsBuffer = 0;
        }
        dividendsRound = _dividendsRound;
    }

     
    function getDividends() public {
        if (dividendsBuffer == 0) revert();
        if (balanceOf[msg.sender] == 0) revert();
        if (paidDividends[msg.sender][dividendsRound] != 0) revert();
        uint256 divAmount = calcDividendsSum(msg.sender);
        if (divAmount >= 100000000000000) {
            if (!msg.sender.send(divAmount)) revert();
        }
    }

     
    function setPrices(uint256 _buyPrice, uint256 _sellPrice) public onlyOwner {
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
    }


     
    function setAllowTransfers(bool _allowTransfers) public onlyOwner {
        allowTransfers = _allowTransfers;
    }

     
    function stopGracePeriod() public onlyOwner {
        gracePeriodStopBlock = block.number;
        buyPrice = 0;
        sellPrice = 0;
    }

     
    function stopICO() public onlyOwner {
        if ( gracePeriodStopBlock > block.number ) gracePeriodStopBlock = block.number;
        
        icoFinished = true;

        weiToPresalersFromICO = icoRaisedETH * percentToPresalersFromICO / 10000;

        if (soldedSupply >= (burnAfterSoldAmount * 100000000)) {

            uint256 companyCost = soldedSupply * 1000000 * 10000;
            companyCost = companyCost / (10000 - percentToFoundersAfterICO) / 1000000;
            
            uint256 amountToFounders = companyCost - soldedSupply;

             
            if (balanceOf[this] > amountToFounders) {
                Burn(this, (balanceOf[this]-amountToFounders));
                balanceOf[this] = 0;
                totalSupply = companyCost;
            } else {
                totalSupply += amountToFounders - balanceOf[this];
            }

            balanceOf[owner] += amountToFounders;
            balanceOf[this] = 0;
            Transfer(this, owner, amountToFounders);
        }

        buyPrice = 0;
        sellPrice = 0;
    }
    
    
     
    function withdrawToFounders(uint256 amount) public onlyOwner {
    	uint256 amount_to_withdraw = amount * 1000000000000000;  
        if ((this.balance - weiToPresalersFromICO) < amount_to_withdraw) revert();
        amount_to_withdraw = amount_to_withdraw / foundersAddresses.length;
        uint8 i = 0;
        uint8 errors = 0;
        
        for (i = 0; i < foundersAddresses.length; i++) {
			if (!foundersAddresses[i].send(amount_to_withdraw)) {
				errors++;
			}
		}
    }
    
    function setBlockPerHour(uint256 _blocksPerHour) public onlyOwner {
    	blocksPerHour = _blocksPerHour;
    }
    
    function setBurnAfterSoldAmount(uint256 _burnAfterSoldAmount)  public onlyOwner {
    	burnAfterSoldAmount = _burnAfterSoldAmount;
    }
    
    function setTransferFromWhiteList(address _from, bool _allow) public onlyOwner {
    	transferFromWhiteList[_from] = _allow;
    }
    
    function addPresaleInvestor(address _addr, uint256 _amountETH, uint256 _amountSTE ) public onlyOwner {    	
	    presaleInvestors[_addr] += _amountSTE;
	    balanceOf[this] -= _amountSTE;
		balanceOf[_addr] += _amountSTE;
	    
	    if ( _amountETH > 0 ) {
	    	presaleInvestorsETH[_addr] += _amountETH;
			balanceOf[this] -= _amountSTE / 10;
			balanceOf[bountyAddr] += _amountSTE / 10;
			 
		}
		
	    Transfer(this, _addr, _amountSTE);
    }
    
         
        
     
    function burn(uint256 amount) public {
        if (balanceOf[msg.sender] < amount) revert();  
        balanceOf[msg.sender] -= amount;  
        totalSupply -= amount;  
        Burn(msg.sender, amount);
    }

     
    function burnContractCoins(uint256 amount) public onlySuperOwner {
        if (balanceOf[this] < amount) revert();  
        balanceOf[this] -= amount;  
        totalSupply -= amount;  
        Burn(this, amount);
    }

     
    function() internal payable {
        buy();
    }
}