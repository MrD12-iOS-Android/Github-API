//
//  RepoListPresenter.swift
//  Repository Finder
//
//  Created by Osama Bin Bashir on 09/12/2018.
//  Copyright © 2018 Osama Bin Bashir. All rights reserved.
//

import Foundation

protocol RepoListPresenter {
    
    var view : PresenterToViewDelegate!{ get }
    var interactor : RepoListPresenterToInteractorDelegate!{ get set }
    var router : RepoListPresenterToRouterDelagate!{ get set}
    
    var viewType : RepoListType{ get }
    var repoListDTO : RepoListDTO? { get }
    var owner : Owner?{ get }
    var totalRepositories : Int{ get }
    var perPageNumber : Int { get }
    var page : Int { get }
    
    func numberOfRows(section : Int)->Int
    func willShowMore()->Bool
    func getRepository(at index : Int)->Repository
    
    
}

class RepoListPresenterImp : RepoListPresenter{
    
    weak var view: PresenterToViewDelegate!
    var interactor: RepoListPresenterToInteractorDelegate!
    var router: RepoListPresenterToRouterDelagate!
    
    var owner: Owner?
    var viewType: RepoListType
    var repoListDTO: RepoListDTO?
    
    var page: Int = 1
    var perPageNumber: Int = 30
    var queryString = ""
    
    var totalRepositories: Int{
        guard let repoListDTO = self.repoListDTO else { return 0}
        return repoListDTO.repositories.count
    }
    
    init(view : PresenterToViewDelegate ,viewType : RepoListType , owner : Owner? = nil) {
        self.view = view
        self.repoListDTO = nil
        self.viewType = viewType
        self.owner = owner
    }
    
    func numberOfRows(section: Int) -> Int {
        var rowCount = 0
        guard let repoListDTO = self.repoListDTO else {
            return rowCount
        }
        if(section == 0){
            
            rowCount = (repoListDTO.showMore) ? repoListDTO.repositories.count + 1: repoListDTO.repositories.count
        }
        
        return rowCount
    }
    
    func willShowMore() -> Bool {
        guard let repoListDTO = self.repoListDTO else { return false }
        return repoListDTO.showMore
    }
    
    func getRepository(at index: Int) -> Repository {
        return repoListDTO!.repositories[index]
        
    }
    
    private func getRepositories(){
        if(viewType == .user){
            guard let userName = owner?.login else {
                self.view.showErrorAlert(with: "Error", message:somethingUnexpectedError )
                return
                
            }
            self.interactor.fetchUserRepositories(userName: userName)
        }
    }
    
    private func getSearchRespositories(queryString : String, page : Int, perPageNumber : Int){
        self.interactor.fetchSearchRepositories(queryString: queryString, page: page , perPageNumber: perPageNumber)
    }
}

extension RepoListPresenterImp : RepoLisViewToPresenterDelegate{
    func viewDidLoad() {
        
    }
    
    func search(queryString: String) {
        self.page = 1
        self.queryString = queryString
        self.repoListDTO?.showMore = false
        self.view.scrollTableViewToTop()
        self.view.startAnimatingLoader()
        self.getSearchRespositories(queryString: queryString, page: self.page, perPageNumber: self.perPageNumber)
    }
    
    func didTapOnRow(with index: Int) {
        self.didTapOnRowHandler(with: index)
    }
    
    private func didTapOnRowHandler(with index : Int){
        if(index == (self.repoListDTO?.repositories.count)!){
            self.showMoreRepositories()
        }else {
            self.showrForksViewHandler(of: index)
        }
    }
    
    private func showrForksViewHandler(of index : Int){
        let numberOfForks = self.repoListDTO?.repositories[index].forks ?? 0
        if(numberOfForks > 0){
            let userName = self.repoListDTO?.repositories[index].owner?.login ?? ""
            let repoName = self.repoListDTO?.repositories[index].name ?? ""
            self.router.pushToForkScreen(repository: repoName, userName: userName, totalForks: numberOfForks)
        }else{
            self.view.showErrorAlert(with: noForksMessage, message: "")
        }
    }
    
    private func showMoreRepositories(){
        self.page = self.page + 1
        self.view.startAnimatingLoader()
        self.getSearchRespositories(queryString: self.queryString, page: self.page, perPageNumber: self.perPageNumber)
    }
    
}

extension RepoListPresenterImp : RepoListInteractorToPresenterDelegate{
    
    func didRepositoriesFetched(repoListDTO: RepoListDTO) {
        self.didRepositoriesFetchedHandler(repoListDTO: repoListDTO)
    }
    
    private func didRepositoriesFetchedHandler(repoListDTO: RepoListDTO){
        self.view.stopAnimatingLoader()

        if(repoListDTO.isError){
            self.repositoriesFetchedErrorHandler(errorMessage: repoListDTO.errorMessage)
        }else {
            self.repositoriesFetchedSuccessfullHandler(repoListDTO: repoListDTO)
        }
    }
    
    private func repositoriesFetchedErrorHandler(errorMessage : String){
        self.view.showErrorAlert(with: "Request Failed", message: errorMessage)
    }
    
    
    private func repositoriesFetchedSuccessfullHandler(repoListDTO: RepoListDTO){
        if(self.willShowMore()){
            self.didRepositoriesFetchedwillShowMoreHandler(repoListDTO: repoListDTO)
        }else{
            self.didRepositoriesFetchedNormalFlowHandler(repoListDTO: repoListDTO)
        }
        self.view.reloadData()
    }
    
    private func didRepositoriesFetchedwillShowMoreHandler(repoListDTO: RepoListDTO){
        
        var repositories =  self.repoListDTO?.repositories
        repositories!.append(contentsOf: repoListDTO.repositories)
        self.repoListDTO = repoListDTO
        self.repoListDTO?.repositories = repositories!
    }
    
    private func didRepositoriesFetchedNormalFlowHandler(repoListDTO: RepoListDTO){
        self.repoListDTO = repoListDTO
        if((self.repoListDTO?.repositories.count)! <= 0){
            self.view.showNoResultFoundAlert()
        }
    }
}











