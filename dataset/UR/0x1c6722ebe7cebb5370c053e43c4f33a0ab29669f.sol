 

pragma solidity 0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



contract Vesting {

    using SafeMath for uint256;

    ERC20 public mycroToken;

    event LogFreezedTokensToInvestor(address _investorAddress, uint256 _tokenAmount, uint256 _daysToFreeze);
    event LogUpdatedTokensToInvestor(address _investorAddress, uint256 _tokenAmount);
    event LogWithdraw(address _investorAddress, uint256 _tokenAmount);

    constructor(address _token) public {
        mycroToken = ERC20(_token);
    }

    mapping (address => Investor) public investors;

    struct Investor {
        uint256 tokenAmount;
        uint256 frozenPeriod;
        bool isInvestor;
    }


     
    function freezeTokensToInvestor(address _investorAddress, uint256 _tokenAmount, uint256 _daysToFreeze) public returns (bool) {
        require(_investorAddress != address(0));
        require(_tokenAmount != 0);
        require(!investors[_investorAddress].isInvestor);

        _daysToFreeze = _daysToFreeze.mul(1 days);  
        
        investors[_investorAddress] = Investor({tokenAmount: _tokenAmount, frozenPeriod: now.add(_daysToFreeze), isInvestor: true});
        
        require(mycroToken.transferFrom(msg.sender, address(this), _tokenAmount));
        emit LogFreezedTokensToInvestor(_investorAddress, _tokenAmount, _daysToFreeze);

        return true;
    }

     function updateTokensToInvestor(address _investorAddress, uint256 _tokenAmount) public returns(bool) {
        require(investors[_investorAddress].isInvestor);
        Investor storage currentInvestor = investors[_investorAddress];
        currentInvestor.tokenAmount = currentInvestor.tokenAmount.add(_tokenAmount);

        require(mycroToken.transferFrom(msg.sender, address(this), _tokenAmount));
        emit LogUpdatedTokensToInvestor(_investorAddress, _tokenAmount);

        return true;
    }

    function withdraw(uint256 _tokenAmount) public {
        address investorAddress = msg.sender;
        Investor storage currentInvestor = investors[investorAddress];
        
        require(currentInvestor.isInvestor);
        require(now >= currentInvestor.frozenPeriod);
        require(_tokenAmount <= currentInvestor.tokenAmount);

        currentInvestor.tokenAmount = currentInvestor.tokenAmount.sub(_tokenAmount);
        require(mycroToken.transfer(investorAddress, _tokenAmount));
        emit LogWithdraw(investorAddress, _tokenAmount);
    }



}