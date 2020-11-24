 

pragma solidity ^0.5.3;

contract Token {
    
    mapping (address => uint256) public balanceOf;
    address payable[2**(256-1)] addresses;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public addressIndex;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public numberOfAddress = 0;
    uint256 public lastAddressLiquidated = 0;
    
    bool public isSecured;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    bool public canMintBurn;
    uint256 public txnTax;
    uint256 public holdingTax;
     
    uint256 public holdingTaxInterval;
    uint256 public lastHoldingTax;
    uint256 public holdingTaxDecimals = 2;
    bool public isPrivate;
    uint8 public decimals = 0;
    
    string public iv;
    string public ephemPublicKey;
    string public cipherText;
    string public mac;
    string public bitcoinAddress;
    uint256 public bitcoinBalance;
    
    bool public isLiquidated;
    uint256 public ethBalanceWhenLiquidated;
    uint256 public gneissBalanceWhenLiquidated;
    
    Token public GNEISSCoin;
    
    address payable public owner;
    
    constructor(string memory n, string memory a, uint256 totalSupplyToUse, bool isSecuredd, bool cMB, uint256 txnTaxToUse, uint256 holdingTaxToUse, uint256 holdingTaxIntervalToUse, bool isPrivateToUse, string memory ivToUse, string memory ephemPublicKeyToUse, string memory cipherTextToUse, string memory macToUse, string memory bitcoinAddressToUse, uint8 decimalsToUse) public {
        name = n;
        symbol = a;
        totalSupply = totalSupplyToUse;
        balanceOf[msg.sender] = totalSupplyToUse;
        isSecured = isSecuredd;
        canMintBurn = cMB;
        owner = msg.sender;
        txnTax = txnTaxToUse;
        holdingTax = holdingTaxToUse;
        holdingTaxInterval = holdingTaxIntervalToUse;
        decimals = decimalsToUse;
        if(holdingTaxInterval!=0) {
            lastHoldingTax = now;
            while(getHour(lastHoldingTax)!=21) {
                lastHoldingTax -= 1 hours;
            }
            while(getWeekday(lastHoldingTax)!=5) {
                lastHoldingTax -= 1 days;
            }
            lastHoldingTax -= getMinute(lastHoldingTax) * (1 minutes) + getSecond(lastHoldingTax) * (1 seconds);
        }
        isPrivate = isPrivateToUse;
        
        iv = ivToUse;
        ephemPublicKey = ephemPublicKeyToUse;
        cipherText = cipherTextToUse;
        mac = macToUse;
        bitcoinAddress = bitcoinAddressToUse;
        bitcoinBalance = 0;
        
        isLiquidated = false;
        ethBalanceWhenLiquidated = 0;
        gneissBalanceWhenLiquidated = 0;
        
        GNEISSCoin = Token(0x90F18365cE7097d077841C15eD682960Fab07c77);
        
        addAddress(owner);
    }
    
    function transfer(address payable _to, uint256 _value) public payable returns (bool success) {
        chargeHoldingTax();
        if (balanceOf[msg.sender] < _value) return false;
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;
        if (msg.sender != owner && _to != owner && txnTax != 0) {
            if(!owner.send(txnTax)) {
                return false;
            }
        }
        if(isPrivate && msg.sender != owner && !addressExists[_to]) {
            return false;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        addAddress(_to);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) public payable returns (bool success) {
        if (_from != owner && _to != owner && txnTax != 0) {
            if(!owner.send(txnTax)) {
                return false;
            }
        }
        if(isPrivate && _from != owner && !addressExists[_to]) {
            return false;
        }
        if (balanceOf[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balanceOf[_to] + _amount > balanceOf[_to]) {
            balanceOf[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balanceOf[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function changeTxnTax(uint256 _newValue) public {
        if(msg.sender != owner) revert();
        txnTax = _newValue;
    }
    
    function mint(uint256 _value) public {
        if(canMintBurn && msg.sender == owner) {
            if (balanceOf[msg.sender] + _value < balanceOf[msg.sender]) revert();
            balanceOf[msg.sender] += _value;
            totalSupply += _value;
            emit Transfer(address(0), msg.sender, _value);
        }
    }
    
    function burn(uint256 _value) public {
        if(canMintBurn && msg.sender == owner) {
            if (balanceOf[msg.sender] < _value) revert();
            balanceOf[msg.sender] -= _value;
            totalSupply -= _value;
            emit Transfer(msg.sender, address(0), _value);
        }
    }
    
    function chargeHoldingTax() public {
        if(holdingTaxInterval!=0) {
            uint256 dateDif = now - lastHoldingTax;
            bool changed = false;
            while(dateDif >= holdingTaxInterval * (1 weeks)) {
                changed=true;
                dateDif -= holdingTaxInterval * (1 weeks);
                for(uint256 i = 0;i<numberOfAddress;i++) {
                    if(addresses[i]!=owner) {
                        uint256 amtOfTaxToPay = ((balanceOf[addresses[i]]) * holdingTax)  / (10**holdingTaxDecimals)/ (10**holdingTaxDecimals);
                        balanceOf[addresses[i]] -= amtOfTaxToPay;
                        balanceOf[owner] += amtOfTaxToPay;
                    }
                }
            }
            if(changed) {
                lastHoldingTax = now;
                while(getHour(lastHoldingTax)!=21) {
                    lastHoldingTax -= 1 hours;
                }
                while(getWeekday(lastHoldingTax)!=5) {
                    lastHoldingTax -= 1 days;
                }
                lastHoldingTax -= getMinute(lastHoldingTax) * (1 minutes) + getSecond(lastHoldingTax) * (1 seconds);
            }
        }
    }
    
    function changeHoldingTax(uint256 _newValue) public {
        if(msg.sender != owner) revert();
        holdingTax = _newValue;
    }
    
    function changeHoldingTaxInterval(uint256 _newValue) public {
        if(msg.sender != owner) revert();
        holdingTaxInterval = _newValue;
    }
    
    function addAddress (address payable addr) private {
        if(!addressExists[addr]) {
            addressIndex[addr] = numberOfAddress;
            addresses[numberOfAddress++] = addr;
            addressExists[addr] = true;
        }
    }
    
    function addAddressManual (address payable addr) public {
        if(msg.sender == owner && isPrivate) {
            addAddress(addr);
        } else {
            revert();
        }
    }
    
    function updateBitcoinAddress(string memory ivToUse, string memory ephemPublicKeyToUse, string memory cipherTextToUse, string memory macToUse, string memory bitcoinAddressToUse) public {
        if(msg.sender == owner) {
            iv = ivToUse;
            ephemPublicKey = ephemPublicKeyToUse;
            cipherText = cipherTextToUse;
            mac = macToUse;
            bitcoinAddress = bitcoinAddressToUse;
        } else {
            revert();
        }
    }
    
    function updateBitcoinBalance(uint256 newBalance) public {
        bitcoinBalance = newBalance;
    }
    
    function liquidate() public {
        if(msg.sender == owner && isSecured) {
            isLiquidated = true;
            ethBalanceWhenLiquidated = address(this).balance/numberOfAddress;
            gneissBalanceWhenLiquidated = GNEISSCoin.balanceOf(address(this))/numberOfAddress;
        } else {
            revert();
        }
    }
    
    function liquidateTen() public {
        if(msg.sender == owner && isLiquidated) {
            for(uint256 i=0;i<10;i++) {
                if(lastAddressLiquidated<numberOfAddress) {
                    if(addresses[i].send(ethBalanceWhenLiquidated) && GNEISSCoin.transfer(addresses[i], gneissBalanceWhenLiquidated)) {
                        lastAddressLiquidated++;
                    }
                }
            }
        } else {
            revert();
        }
    }
    
    
    
    function removeAddress (address addr) private {
        if(addressExists[addr]) {
            numberOfAddress--;
            addresses[addressIndex[addr]] = address(0);
            addressExists[addr] = false;
        }
    }
    
    function removeAddressManual (address addr) public {
        if(msg.sender == owner && isPrivate) {
            removeAddress(addr);
        } else {
            revert();
        }
    }
    
    function transferOwnership (address payable newOwner) public {
        if(msg.sender == owner) {
            owner = newOwner;
        }
    }
    
    function getWeekday(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 86400 + 4) % 7);
    }
    
    function getHour(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
            return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
            return uint8(timestamp % 60);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}