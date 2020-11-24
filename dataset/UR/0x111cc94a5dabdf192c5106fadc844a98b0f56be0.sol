 

contract DAO {
    function balanceOf(address addr) returns (uint);
    function transferFrom(address from, address to, uint balance) returns (bool);
    function getNewDAOAddress(uint _proposalID) constant returns(address _newDAO);
    uint public totalSupply;
}

 
contract trustedChildWithdraw {

  DAO constant public mainDAO = DAO(0xbb9bc244d798123fde783fcc1c72d3bb8c189413);
  uint[] public trustedProposals = [7, 10, 16, 20, 23, 26, 27, 28, 31, 34, 37, 39, 41, 44, 54, 57, 60, 61, 63, 64, 65, 66];
  mapping (uint => DAO) public whiteList;
  address constant curator = 0xda4a4626d3e16e094de3225a751aab7128e96526;

   
  function trustedChildWithdraw() {
      for(uint i=0; i<trustedProposals.length; i++) {
          uint proposalId = trustedProposals[i];
          whiteList[proposalId] = DAO(mainDAO.getNewDAOAddress(proposalId));
      }
  }

   
  function requiredEndowment() constant returns (uint endowment) {
      uint sum = 0;
      for(uint i=0; i<trustedProposals.length; i++) {
          uint proposalId = trustedProposals[i];
          DAO childDAO = whiteList[proposalId];
          sum += childDAO.totalSupply();
      }
      return sum;
  }

   
  function withdraw(uint proposalId) external {
     
    uint balance = whiteList[proposalId].balanceOf(msg.sender);

     
    if (!whiteList[proposalId].transferFrom(msg.sender, this, balance) || !msg.sender.send(balance))
      throw;
  }

   
  function clawback() external {
    if (msg.sender != curator) throw;
    if (!curator.send(this.balance)) throw;
  }

}