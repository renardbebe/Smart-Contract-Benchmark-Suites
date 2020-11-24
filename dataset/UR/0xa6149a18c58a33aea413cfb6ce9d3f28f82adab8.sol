 

pragma solidity ^0.4.18;

contract DelegateERC20 {
  function delegateTotalSupply() public view returns (uint256);
  function delegateBalanceOf(address who) public view returns (uint256);
  function delegateTransfer(address to, uint256 value, address origSender) public returns (bool);
  function delegateAllowance(address owner, address spender) public view returns (uint256);
  function delegateTransferFrom(address from, address to, uint256 value, address origSender) public returns (bool);
  function delegateApprove(address spender, uint256 value, address origSender) public returns (bool);
  function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public returns (bool);
  function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public returns (bool);
}
contract Ownable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function transferOwnership(address newOwner) public;
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  function pause() public;
  function unpause() public;
}
contract CanReclaimToken is Ownable {
  function reclaimToken(ERC20Basic token) external;
}
contract Claimable is Ownable {
  function transferOwnership(address newOwner) public;
  function claimOwnership() public;
}
contract AddressList is Claimable {
    event ChangeWhiteList(address indexed to, bool onList);
    function changeList(address _to, bool _onList) public;
}
contract HasNoContracts is Ownable {
  function reclaimContract(address contractAddr) external;
}
contract HasNoEther is Ownable {
  function() external;
  function reclaimEther() external;
}
contract HasNoTokens is CanReclaimToken {
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}
contract AllowanceSheet is Claimable {
    function addAllowance(address tokenHolder, address spender, uint256 value) public;
    function subAllowance(address tokenHolder, address spender, uint256 value) public;
    function setAllowance(address tokenHolder, address spender, uint256 value) public;
}
contract BalanceSheet is Claimable {
    function addBalance(address addr, uint256 value) public;
    function subBalance(address addr, uint256 value) public;
    function setBalance(address addr, uint256 value) public;
}
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract BasicToken is ERC20Basic, Claimable {
  function setBalanceSheet(address sheet) external;
  function totalSupply() public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal;
  function balanceOf(address _owner) public view returns (uint256 balance);
}
contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);
  function burn(uint256 _value) public;
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeERC20 {
}
contract StandardToken is ERC20, BasicToken {
  function setAllowanceSheet(address sheet) external;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function transferAllArgsYesAllowance(address _from, address _to, uint256 _value, address spender) internal;
  function approve(address _spender, uint256 _value) public returns (bool);
  function approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal;
  function allowance(address _owner, address _spender) public view returns (uint256);
  function increaseApproval(address _spender, uint _addedValue) public returns (bool);
  function increaseApprovalAllArgs(address _spender, uint _addedValue, address tokenHolder) internal;
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool);
  function decreaseApprovalAllArgs(address _spender, uint _subtractedValue, address tokenHolder) internal;
}
contract CanDelegate is StandardToken {
    event DelegatedTo(address indexed newContract);
    function delegateToNewContract(DelegateERC20 newContract) public;
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address _owner, address spender) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function increaseApproval(address spender, uint addedValue) public returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool);
}
contract StandardDelegate is StandardToken, DelegateERC20 {
    function setDelegatedFrom(address addr) public;
    function delegateTotalSupply() public view returns (uint256);
    function delegateBalanceOf(address who) public view returns (uint256);
    function delegateTransfer(address to, uint256 value, address origSender) public returns (bool);
    function delegateAllowance(address owner, address spender) public view returns (uint256);
    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public returns (bool);
    function delegateApprove(address spender, uint256 value, address origSender) public returns (bool);
    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public returns (bool);
    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public returns (bool);
}
contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);
}
contract TrueUSD is StandardDelegate, PausableToken, BurnableToken, NoOwner, CanDelegate {
    event ChangeBurnBoundsEvent(uint256 newMin, uint256 newMax);
    event Mint(address indexed to, uint256 amount);
    event WipedAccount(address indexed account, uint256 balance);
    function setLists(AddressList _canReceiveMintWhiteList, AddressList _canBurnWhiteList, AddressList _blackList, AddressList _noFeesList) public;
    function changeName(string _name, string _symbol) public;
    function burn(uint256 _value) public;
    function mint(address _to, uint256 _amount) public;
    function changeBurnBounds(uint newMin, uint newMax) public;
    function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal;
    function wipeBlacklistedAccount(address account) public;
    function payStakingFee(address payer, uint256 value, uint80 numerator, uint80 denominator, uint256 flatRate, address otherParticipant) private returns (uint256);
    function changeStakingFees(uint80 _transferFeeNumerator, uint80 _transferFeeDenominator, uint80 _mintFeeNumerator, uint80 _mintFeeDenominator, uint256 _mintFeeFlat, uint80 _burnFeeNumerator, uint80 _burnFeeDenominator, uint256 _burnFeeFlat) public;
    function changeStaker(address newStaker) public;
}



 
library NewSafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
   
    contract Cash311 {
         
           
        using NewSafeMath for uint;

         
           
        address owner;

         
           
        TrueUSD public token = TrueUSD(0x8dd5fbce2f6a956c3022ba3663759011dd51e73e);

         
           
        uint private decimals = 10**16;

         
           
        mapping (address => uint) deposit;
        uint deposits;

         
           
        mapping (address => uint) withdrawn;

         
           
        mapping (address => uint) lastTimeWithdraw;


         
        mapping (address => uint) referals1;
        mapping (address => uint) referals2;
        mapping (address => uint) referals3;
        mapping (address => uint) referals1m;
        mapping (address => uint) referals2m;
        mapping (address => uint) referals3m;
        mapping (address => address) referers;
        mapping (address => bool) refIsSet;
        mapping (address => uint) refBonus;


         
           
        function Cash311() public {
             
               
            owner = msg.sender;
        }

         
           
        function transferOwnership(address _newOwner) external {
            require(msg.sender == owner);
            require(_newOwner != address(0));
            owner = _newOwner;
        }

         
        function bytesToAddress1(bytes source) internal pure returns(address parsedReferer) {
            assembly {
                parsedReferer := mload(add(source,0x14))
            }
            return parsedReferer;
        }

         
           
        function getInfo(address _address) public view returns(uint Deposit, uint Withdrawn, uint AmountToWithdraw, uint Bonuses) {

             
               
            Deposit = deposit[_address].div(decimals);
             
               
            Withdrawn = withdrawn[_address].div(decimals);
             
             
               
               
            uint _a = (block.timestamp.sub(lastTimeWithdraw[_address])).div(1 days).mul(deposit[_address].mul(311).div(10000));
            AmountToWithdraw = _a.div(decimals);
             
            Bonuses = refBonus[_address].div(decimals);
        }

         
        function getRefInfo(address _address) public view returns(uint Referals1, uint Referals1m, uint Referals2, uint Referals2m, uint Referals3, uint Referals3m) {
            Referals1 = referals1[_address];
            Referals1m = referals1m[_address].div(decimals);
            Referals2 = referals2[_address];
            Referals2m = referals2m[_address].div(decimals);
            Referals3 = referals3[_address];
            Referals3m = referals3m[_address].div(decimals);
        }

        function getNumber() public view returns(uint) {
            return deposits;
        }

        function getTime(address _address) public view returns(uint Hours, uint Minutes) {
            Hours = (lastTimeWithdraw[_address] % 1 days) / 1 hours;
            Minutes = (lastTimeWithdraw[_address] % 1 days) % 1 hours / 1 minutes;
        }




         
           
        function() external payable {

             
               
            msg.sender.transfer(msg.value);
             
             
             
               
               
               
            uint _approvedTokens = token.allowance(msg.sender, address(this));
            if (_approvedTokens == 0 && deposit[msg.sender] > 0) {
                withdraw();
                return;
             
               
            } else {
                if (msg.data.length == 20) {
                    address referer = bytesToAddress1(bytes(msg.data));
                    if (referer != msg.sender) {
                        invest(referer);
                        return;
                    }
                }
                invest(0x0);
                return;
            }
        }

         
        function refSystem(uint _value, address _referer) internal {
            refBonus[_referer] = refBonus[_referer].add(_value.div(40));
            referals1m[_referer] = referals1m[_referer].add(_value);
            if (refIsSet[_referer]) {
                address ref2 = referers[_referer];
                refBonus[ref2] = refBonus[ref2].add(_value.div(50));
                referals2m[ref2] = referals2m[ref2].add(_value);
                if (refIsSet[referers[_referer]]) {
                    address ref3 = referers[referers[_referer]];
                    refBonus[ref3] = refBonus[ref3].add(_value.mul(3).div(200));
                    referals3m[ref3] = referals3m[ref3].add(_value);
                }
            }
        }

         
        function setRef(uint _value, address referer) internal {

            if (deposit[referer] > 0) {
                referers[msg.sender] = referer;
                refIsSet[msg.sender] = true;
                referals1[referer] = referals1[referer].add(1);
                if (refIsSet[referer]) {
                    referals2[referers[referer]] = referals2[referers[referer]].add(1);
                    if (refIsSet[referers[referer]]) {
                        referals3[referers[referers[referer]]] = referals3[referers[referers[referer]]].add(1);
                    }
                }
                refBonus[msg.sender] = refBonus[msg.sender].add(_value.div(50));
                refSystem(_value, referer);
            }
        }



         
           
        function invest(address _referer) public {

             
               
            uint _value = token.allowance(msg.sender, address(this));

             
               
            token.transferFrom(msg.sender, address(this), _value);
             
               
            refBonus[owner] = refBonus[owner].add(_value.div(10));

             
               
            if (deposit[msg.sender] > 0) {
                 
                 
                   
                   
                uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender])).div(1 days).mul(deposit[msg.sender].mul(311).div(10000));
                 
                   
                if (amountToWithdraw != 0) {
                     
                       
                    withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
                     
                       
                    token.transfer(msg.sender, amountToWithdraw);

                     
                    uint _bonus = refBonus[msg.sender];
                    if (_bonus != 0) {
                        refBonus[msg.sender] = 0;
                        token.transfer(msg.sender, _bonus);
                        withdrawn[msg.sender] = withdrawn[msg.sender].add(_bonus);
                    }

                }
                 
                   
                lastTimeWithdraw[msg.sender] = block.timestamp;
                 
                   
                deposit[msg.sender] = deposit[msg.sender].add(_value);
                 
                   

                 
                if (refIsSet[msg.sender]) {
                      refSystem(_value, referers[msg.sender]);
                  } else if (_referer != 0x0 && _referer != msg.sender) {
                      setRef(_value, _referer);
                  }
                return;
            }
             
             
               
               
            lastTimeWithdraw[msg.sender] = block.timestamp;
             
             
            deposit[msg.sender] = (_value);
            deposits += 1;

             
            if (refIsSet[msg.sender]) {
                refSystem(_value, referers[msg.sender]);
            } else if (_referer != 0x0 && _referer != msg.sender) {
                setRef(_value, _referer);
            }
        }

         
           
        function withdraw() public {

             
             
               
               
            uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender])).div(1 days).mul(deposit[msg.sender].mul(311).div(10000));
             
               
            if (amountToWithdraw == 0) {
                revert();
            }
             
               
            withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
             
             
               
               
            lastTimeWithdraw[msg.sender] = block.timestamp.sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days));
             
               
            token.transfer(msg.sender, amountToWithdraw);

             
            uint _bonus = refBonus[msg.sender];
            if (_bonus != 0) {
                refBonus[msg.sender] = 0;
                token.transfer(msg.sender, _bonus);
                withdrawn[msg.sender] = withdrawn[msg.sender].add(_bonus);
            }

        }
    }