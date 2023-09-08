// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function addWhitelist(address _addressToWhitelist) external;
    function verifyUser(address _whitelistedAddress) external view returns(bool);
    function removeFromWhitelist(address[] calldata toRemoveAddresses)external;
}
contract Governance {
    address public admin;
    uint256 public totalVotes;
    uint count=1;

    mapping(address =>mapping(uint256=>bool) ) public hasVoted;
    struct proposals{
        address tokenaddresses;
        address walletadrress;
        uint  amount;
        uint totalvotes;
        uint timestamp;
        bool pass;
    }
    mapping (uint256=>proposals)public _proposals;
    constructor() {
        admin = msg.sender;
       }
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    function proposal(address wallet, uint256 _amount,address _tokenaddress) external onlyAdmin {
            _proposals[count]=proposals(_tokenaddress,wallet,_amount,0,block.timestamp,false);
            count++;
    }
    function vote(uint proposalid) external  {
        require(_proposals[proposalid].pass==false,"Proposal Already Passed");
        require(_proposals[proposalid].timestamp!=0,"No created proposalid");
        require(hasVoted[msg.sender][proposalid]==false, "You have already voted");
        require(IERC20(_proposals[proposalid].tokenaddresses).verifyUser(msg.sender), "Not whitelisted");
       
        _proposals[proposalid].totalvotes+=IERC20(_proposals[proposalid].tokenaddresses).balanceOf(msg.sender);

        if (_proposals[proposalid].totalvotes >=(IERC20(_proposals[proposalid].tokenaddresses).totalSupply()*51)/100) {
            _proposals[proposalid].pass=true;
       }
    }
    function proposalStatus(uint proposalid) external view returns(bool,address,uint){
        return  (_proposals[proposalid].pass, _proposals[proposalid].walletadrress, _proposals[proposalid].amount);
    }
}
