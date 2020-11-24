 

contract DAO {
    function balanceOf(address addr) returns (uint);
    function transferFrom(address from, address to, uint balance) returns (bool);
}


contract WithDrawChildDAO {

    struct SplitData {
        uint128 balance;
        uint128 totalSupply;
    }
    mapping (address => SplitData) childDAOs;

    function WithDrawPreForkChildDAO() {
         
         
         
         
         
         
        
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        childDAOs[0x9c15b54878ba618f494b38f0ae7443db6af648ba] = SplitData(7913415994245080851884568, 11540303342793816418782834);
         
        childDAOs[0x21c7fdb9ed8d291d79ffd82eb2c4356ec0d81241] = SplitData(7913416021673878030553201, 11540303382793816418782834); 
         
         
         
         
         
         
         
        childDAOs[0x0737a6b837f97f46ebade41b9bc3e1c509c85c53] = SplitData(8285423727021618574288915, 11597611623386926056781866);
         
         
         
         
         
         
         
        childDAOs[0x9da397b9e80755301a3b32173283a91c0ef6c87e] = SplitData(7930699229747195847409685, 11562914862736318056781866);
         
         
         
         
         
        childDAOs[0x1cba23d343a983e9b5cfd19496b9a9701ada385f] = SplitData(7929078466662085333989346, 11560551799275847356782634);
         
        childDAOs[0x9fcd2deaff372a39cc679d5c5e4de7bafb0b1339] = SplitData(10112931316104865578090844, 11599318102767995456781865);
         
         
        childDAOs[0xbc07118b9ac290e4622f5e77a0853539789effbe] = SplitData(7932411170508884080269057, 11565410862736318056781866);
         
        childDAOs[0xacd87e28b0c9d1254e868b81cba4cc20d9a32225] = SplitData(7913413658817663126469710, 11540299982102102518782834);
         
        childDAOs[0x5524c55fb03cf21f549444ccbecb664d0acad706] = SplitData(7920435670452017684678746, 11550426779375303418782834);
         
         
        childDAOs[0x253488078a4edf4d6f42f113d1e62836a942cf1a] = SplitData(7913160958906206858622565, 11539990270685330718782834);
         
         
         
         
        childDAOs[0x6d87578288b6cb5549d5076a207456a1f6a63dc0] = SplitData(7912878490620133004657286, 11539954374724178476032701);
         
         
         
         
    }

    function withdraw(DAO _childDAO){
        uint balance = _childDAO.balanceOf(msg.sender);
        uint amount = balance * childDAOs[_childDAO].totalSupply / childDAOs[_childDAO].balance;
        if (!_childDAO.transferFrom(msg.sender, this, balance) || !msg.sender.send(amount))
            throw;
       }

    function checkMyWithdraw(DAO _childDAO, address _tokenHolder) constant returns(uint) {        
        return _childDAO.balanceOf(_tokenHolder) * childDAOs[_childDAO].totalSupply / childDAOs[_childDAO].balance;
    }

    address constant curator = 0xda4a4626d3e16e094de3225a751aab7128e96526;
    
     
    function clawback() external {
        if (msg.sender != curator) throw;
        if (!curator.send(this.balance)) throw;
    }
}