 

pragma solidity ^0.4.15;

 

contract IICOInfo {
  function estimate(uint256 _wei) public constant returns (uint tokens);
  function purchasedTokenBalanceOf(address addr) public constant returns (uint256 tokens);
  function isSaleActive() public constant returns (bool active);
}

 

contract IMintableToken {
    function mint(address _to, uint256 _amount);
}

 

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 

contract ReenterableMinter is Ownable {
    event MintSuccess(bytes32 indexed mint_id);

    function ReenterableMinter(IMintableToken token){
        m_token = token;
    }

    function mint(bytes32 mint_id, address to, uint256 amount) onlyOwner {
         
        if (!m_processed_mint_id[mint_id]) {
            m_token.mint(to, amount);
            m_processed_mint_id[mint_id] = true;
        }
        MintSuccess(mint_id);
    }

    IMintableToken public m_token;
    mapping(bytes32 => bool) public m_processed_mint_id;
}