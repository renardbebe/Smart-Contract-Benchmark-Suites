 

pragma solidity 0.4.6;

contract DXF_Tokens{

   
  bool public dxfOpen=true;
  bool public refundState;
  bool public transferLocked=true;

  uint256 public startingDateFunding;
  uint256 public closingDateFunding;
   
  uint256 public constant maxNumberMembers=5000;
   
  uint256 public totalTokens;
  uint256 public constant tokensCreationMin = 25000 ether;
  uint256 public constant tokensCreationCap = 75000 ether;
   
   
  uint256 public remainingTokensVIPs=12500 ether;
  uint256 public constant tokensCreationVIPsCap = 12500 ether; 


  mapping (address => uint256) balances;
  mapping (address => bool) vips;
  mapping (address => uint256) indexMembers;
  
  struct Member
  {
    address member;
    uint timestamp;
    uint initial_value;
  }
  Member[] public members;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Refund(address indexed _to, uint256 _value);
  event failingRefund(address indexed _to, uint256 _value);
  event VipMigration(address indexed _vip, uint256 _value);
  event newMember(address indexed _from);

   
  string public constant name = "DXF - Decentralized eXperience Friends";
  string public constant symbol = "DXF";
  uint8 public constant decimals = 18;   

  address public admin;
  address public multisigDXF;

  modifier onlyAdmin()
  {
    if (msg.sender!=admin) throw;
    _;
  }

  function DXF_Tokens()
  {
    admin = msg.sender;
    startingDateFunding=now;
    multisigDXF=0x7a992f486fbc7C03a3f2f862Ad260f158C5c5486;  
     
    members.push(Member(0,0,0));
  }


   
  function ()
    {
      throw;
    }

   
   
   
   
   
  function acceptTermsAndJoinDXF() payable external 
  {
     
    if (now>startingDateFunding+365 days) throw;
     
    if (!dxfOpen) throw;
     
    if (vips[msg.sender]) throw;
     
    if (msg.value < 10 ether) throw;
    if (msg.value > (tokensCreationCap - totalTokens)) throw;
     
    if (msg.value > (10000 ether - balances[msg.sender])) throw;
     
    if (balances[msg.sender]==0)
      {
        newMember(msg.sender);  
	indexMembers[msg.sender]=members.length;
	members.push(Member(msg.sender,now,msg.value));
      }
    else
      {
	members[indexMembers[msg.sender]].initial_value+=msg.value;
      }
    if (members.length>maxNumberMembers) throw;
     
    if (multisigDXF==0) throw;
    if (!multisigDXF.send(msg.value)) throw;
     
    uint numTokens = msg.value;
    totalTokens += numTokens;
     
    if ( (tokensCreationCap-totalTokens) < remainingTokensVIPs ) throw;
    balances[msg.sender] += numTokens;
     
    Transfer(0, msg.sender, numTokens);
  }



   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   


   
   
   
   
   
  function fullTransfer(address _to) returns (bool)
  {
     
    if (transferLocked) throw;
    if (balances[_to]!=0) throw;
    if (balances[msg.sender]!=0)
      {
	uint senderBalance = balances[msg.sender];
	balances[msg.sender] = 0;
	balances[_to]=senderBalance;
	if (vips[msg.sender])
	  {
	    vips[_to]=true;
	    vips[msg.sender]=false;
	  }
	members[indexMembers[msg.sender]].member=_to;
	indexMembers[_to]=indexMembers[msg.sender];
	indexMembers[msg.sender]=0;
	Transfer(msg.sender, _to, senderBalance);
	return true;
      }
    else
      {
	return false;
      }
  }


   


   
   
   
   
  function registerVIP(address _vip, address _vip_confirm, uint256 _previous_balance)
    onlyAdmin
  {
    if (_vip==0) throw;
    if (_vip!=_vip_confirm) throw;
     
    if (balances[_vip]!=0) throw; 
    if (_previous_balance==0) throw;
    uint numberTokens=_previous_balance+(_previous_balance/3);
    totalTokens+=numberTokens;
     
    if (numberTokens>remainingTokensVIPs) throw;     
    remainingTokensVIPs-=numberTokens;
    balances[_vip]+=numberTokens;
    indexMembers[_vip]=members.length;
    members.push(Member(_vip,now,_previous_balance));
    vips[_vip]=true;
    VipMigration(_vip,_previous_balance);
  }


   
  function paybackContribution(uint i)
    payable
    onlyAdmin
  {
    address memberRefunded=members[i].member;
    if (memberRefunded==0) throw;
    uint amountTokens=msg.value;
    if (vips[memberRefunded]) 
      {
	amountTokens+=amountTokens/3;
	remainingTokensVIPs+=amountTokens;
      }
    if (amountTokens>balances[memberRefunded]) throw;
    balances[memberRefunded]-=amountTokens;
    totalTokens-=amountTokens;
    if (balances[memberRefunded]==0) 
      {
	delete members[i];
	vips[memberRefunded]=false;
	indexMembers[memberRefunded]=0;
      }
    if (!memberRefunded.send(msg.value))
      {
        failingRefund(memberRefunded,msg.value);
      }
    Refund(memberRefunded,msg.value);
  }


  function changeAdmin(address _admin, address _admin_confirm)
    onlyAdmin
  {
    if (_admin!=_admin_confirm) throw;
    if (_admin==0) throw;
    admin=_admin;
  }

   
   
   
  function closeFunding()
    onlyAdmin
  {
    closingDateFunding=now;
    dxfOpen=false;
     
     
    if (totalTokens<tokensCreationMin)
      {
	refundState=true;
      }
    else
      {
         
	if(!admin.send(this.balance)) throw;
      }
  }

   
   
   
   
   
   
   

  function allowTransfers()
    onlyAdmin
  {
    transferLocked=false;
  }

  function disableTransfers()
    onlyAdmin
  {
    transferLocked=true;
  }


   
  function totalSupply() external constant returns (uint256) 
  {
    return totalTokens;
  }

  function balanceOf(address _owner) external constant returns (uint256) 
  {
    return balances[_owner];
  }

  function accountInformation(address _owner) external constant returns (bool vip, uint balance_dxf, uint share_dxf_per_thousands) 
  {
    vip=vips[_owner];
    balance_dxf=balances[_owner]/(1 ether);
    share_dxf_per_thousands=1000*balances[_owner]/totalTokens;
  }


}