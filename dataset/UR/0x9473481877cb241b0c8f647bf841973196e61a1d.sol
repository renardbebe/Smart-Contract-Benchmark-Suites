 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract Prop {
    function noFeeTransfer(address _to, uint256 _value) public returns (bool);
    function mintTokens(address _atAddress, uint256 _amount) public;

}

contract BST {
    function balanceOf(address _owner) public constant returns (uint256 _balance);
}

contract FirstBuyers is Ownable {
    using SafeMath for uint256;

     
    modifier onlyFirstBuyer() {
        require(firstBuyers[msg.sender].tokensReceived > 0);
        _;
    }

     
    struct FirstBuyer {
        uint256 lastTransactionIndex;
        uint256 tokensReceived;
        uint256 weightedContribution;
    }

     
    mapping(address => FirstBuyer) firstBuyers;
    mapping(uint256 => uint256) transactions;
    mapping(uint256 => address) firstBuyerIndex;

     
    uint256 numOfTransaction;
    uint256 numOfFirstBuyers = 0;
    uint256 totalWeightedContribution;
    Prop property;
    BST bst;

    event FirstBuyerWhitdraw(address indexed _firstBuyer, uint256 _amount);
    event NewTransactionOfTokens(uint256 _amount, uint256 _index);

     
    constructor(address _property,  address _owner) public {
        property = Prop(_property);
        owner = _owner;
        bst = BST(0x509A38b7a1cC0dcd83Aa9d06214663D9eC7c7F4a);
    }

     
    function addFirstBuyers(address[] _addresses, uint256[] _amount) public onlyOwner {
        require(_addresses.length == _amount.length);
        for(uint256 i = 0; i < _addresses.length; i++) {
            uint256 weightedContribution = (bst.balanceOf(_addresses[i]).mul(_amount[i])).div(10**18);

            FirstBuyer storage buyer = firstBuyers[_addresses[i]];
            uint256 before = buyer.tokensReceived;
            buyer.tokensReceived = buyer.tokensReceived.add(_amount[i]);
            buyer.weightedContribution = buyer.weightedContribution.add(weightedContribution);

            property.mintTokens(_addresses[i], _amount[i]);
            firstBuyers[_addresses[i]] = buyer;

            totalWeightedContribution = totalWeightedContribution.add(weightedContribution);
            if(before == 0) {
                firstBuyerIndex[numOfFirstBuyers] = _addresses[i];
                numOfFirstBuyers++;
            }
        }
    }

     
    function withdrawTokens() public onlyFirstBuyer {
        FirstBuyer storage buyer = firstBuyers[msg.sender];
        require(numOfTransaction >= buyer.lastTransactionIndex);
        uint256 iterateOver = numOfTransaction.sub(buyer.lastTransactionIndex);
        if (iterateOver > 30) {
            iterateOver = 30;
        }
        uint256 iterate = buyer.lastTransactionIndex.add(iterateOver);
        uint256 amount = 0;
        for (uint256 i = buyer.lastTransactionIndex; i < iterate; i++) {
            uint256 ratio = ((buyer.weightedContribution.mul(10**14)).div(totalWeightedContribution));
            amount = amount.add((transactions[buyer.lastTransactionIndex].mul(ratio)).div(10**14));
            buyer.lastTransactionIndex = buyer.lastTransactionIndex.add(1);
        }
        assert(property.noFeeTransfer(msg.sender, amount));
        emit FirstBuyerWhitdraw(msg.sender, amount);
    }

     
    function incomingTransaction(uint256 _amount) public {
        require(msg.sender == address(property));
        transactions[numOfTransaction] = _amount;
        numOfTransaction += 1;
        emit NewTransactionOfTokens(_amount, numOfTransaction);
    }

     
    function getFirstBuyer(address _firstBuyer) constant public returns (uint256, uint256, uint256) {
        return (firstBuyers[_firstBuyer].lastTransactionIndex,firstBuyers[_firstBuyer].tokensReceived,firstBuyers[_firstBuyer].weightedContribution);
    }

     
    function getNumberOfFirstBuyer() constant public returns(uint256) {
        return numOfFirstBuyers;
    }

     
    function getFirstBuyerAddress(uint256 _index) constant public returns(address) {
        return firstBuyerIndex[_index];
    }

     
    function getNumberOfTransactions() constant public returns(uint256) {
        return numOfTransaction;
    }

     
    function getTotalWeightedContribution() constant public returns(uint256) {
        return totalWeightedContribution;
    }

     
    function () public payable {
        revert();
    }
}


 
 
 

contract ERC20Token {

     
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 _balance);
    function transfer(address _to, uint256 _amount) public returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success);
    function approve(address _spender, uint256 _amount) public returns (bool _success);
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}

contract Data {
    function canMakeNoFeeTransfer(address _from, address _to) constant public returns(bool);
    function getNetworkFee() public constant returns (uint256);
    function getBlocksquareFee() public constant returns (uint256);
    function getCPFee() public constant returns (uint256);
    function getFirstBuyersFee() public constant returns (uint256);
    function hasPrestige(address _owner) public constant returns(bool);
}

 
 
 

contract PropToken is ERC20Token, Ownable {
    using SafeMath for uint256;

    struct Prop {
        string primaryPropertyType;
        string secondaryPropertyType;
        uint64 cadastralMunicipality;
        uint64 parcelNumber;
        uint64 id;
    }


     
    string mapURL = "https://www.google.com/maps/place/Tehnolo%C5%A1ki+park+Ljubljana+d.o.o./@46.0491873,14.458252,17z/data=!3m1!4b1!4m5!3m4!1s0x477ad2b1cdee0541:0x8e60f36e738253f0!8m2!3d46.0491873!4d14.4604407";
    string public name = "PropToken BETA 000000000001";  
    string public symbol = "BSPT-BETA-000000000001";  
    uint8 public decimals = 18;  
    uint8 public numOfProperties;

    bool public tokenFrozen;  

     
    FirstBuyers public firstBuyers;  
    address public networkReserveFund;  
    address public blocksquare;  
    address public certifiedPartner;  

     
    uint256 supply;  
    uint256 MAXSUPPLY = 100000 * 10 ** 18;  
    uint256 feePercent;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    Data data;

    Prop[] properties;

     
    event TokenFrozen(bool _frozen, string _reason);
    event Mint(address indexed _to, uint256 _value);

     
    constructor() public {
        owner = msg.sender;
        tokenFrozen = true;
        feePercent = 2;
        networkReserveFund = address(0x7E8f1b7655fc05e48462082E5A12e53DBc33464a);
        blocksquare = address(0x84F4CE7a40238062edFe3CD552cacA656d862f27);
        certifiedPartner = address(0x3706E1CdB3254a1601098baE8D1A8312Cf92f282);
        firstBuyers = new FirstBuyers(this, owner);
    }

     
    function addProperty(string _primaryPropertyType, string _secondaryPropertyType, uint64 _cadastralMunicipality, uint64 _parcelNumber, uint64 _id) public onlyOwner {
        properties.push(Prop(_primaryPropertyType, _secondaryPropertyType, _cadastralMunicipality, _parcelNumber, _id));
        numOfProperties++;
    }

     
    function setDataFactory(address _data) public onlyOwner {
        data = Data(_data);
    }

     
    function noFee(address _from, address _to, uint256 _amount) private returns (bool) {
        require(!tokenFrozen);
        require(balances[_from] >= _amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
    function noFeeTransfer(address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == address(firstBuyers));
        return noFee(msg.sender, _to, _amount);
    }

     
    function distributeFee(uint256 _fee) private {
        balances[networkReserveFund] = balances[networkReserveFund].add((_fee.mul(data.getNetworkFee())).div(100));
        balances[blocksquare] = balances[blocksquare].add((_fee.mul(data.getBlocksquareFee())).div(100));
        balances[certifiedPartner] = balances[certifiedPartner].add((_fee.mul(data.getCPFee())).div(100));
        balances[address(firstBuyers)] = balances[address(firstBuyers)].add((_fee.mul(data.getFirstBuyersFee())).div(100));
        firstBuyers.incomingTransaction((_fee.mul(data.getFirstBuyersFee())).div(100));
    }

     
    function _transfer(address _from, address _to, uint256 _amount) private {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _amount);
        uint256 fee = (_amount.mul(feePercent)).div(100);
        distributeFee(fee);
        balances[_to] = balances[_to].add(_amount.sub(fee));
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount.sub(fee));
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(!tokenFrozen);
        if (data.canMakeNoFeeTransfer(msg.sender, _to) || data.hasPrestige(msg.sender)) {
            noFee(msg.sender, _to, _amount);
        }
        else {
            _transfer(msg.sender, _to, _amount);
        }
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_amount <= allowances[_from][msg.sender]);
        require(!tokenFrozen);
        _transfer(_from, _to, _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        return true;
    }

     
    function mintTokens(address _atAddress, uint256 _amount) public {
        require(msg.sender == address(firstBuyers));
        require(balances[_atAddress].add(_amount) > balances[_atAddress]);
        require((supply.add(_amount)) <= MAXSUPPLY);
        supply = supply.add(_amount);
        balances[_atAddress] = balances[_atAddress].add(_amount);
        emit Mint(_atAddress, _amount);
        emit Transfer(0x0, _atAddress, _amount);
    }

     
    function changeFreezeTransaction(string _reason) public onlyOwner {
        tokenFrozen = !tokenFrozen;
        emit TokenFrozen(tokenFrozen, _reason);
    }

     
    function changeFee(uint256 _fee) public onlyOwner {
        feePercent = _fee;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

     
    function totalSupply() public constant returns (uint256) {
        return supply;
    }

     
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

     
    function getPropertyInfo(uint8 _index) public constant returns (string, string, uint64, uint64, uint64) {
        return (properties[_index].primaryPropertyType, properties[_index].secondaryPropertyType, properties[_index].cadastralMunicipality, properties[_index].parcelNumber, properties[_index].id);
    }

     
    function getMap() public constant returns (string) {
        return mapURL;
    }
}