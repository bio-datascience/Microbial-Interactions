


#' run trac on all levels (1st stage) for multiple train-test splits (on cluster)
#'
#'
level_names <- rev(names(dat_list))
log_pseudo <- function(x, pseudo_count = 1) log(x + pseudo_count)

# apply trac on 10 random train-test splits...
set.seed(123)
nsplit <- 10
ntot <- length(dat_list$OTU$y)
n <- round(2/3 * ntot)

tr <- list()
fit <- list()
cvfit <- list()
yhat_tr <- list()
yhat_te <- list()
trainerr <- list()
testerr <- list()
nnz <- list()
for (j in seq(nsplit)) {
  cat("split", j, fill = TRUE)
  tr[[j]] <- sample(ntot, n)
  fit[[j]] <- list()
  cvfit[[j]] <- list()
  yhat_tr[[j]] <- list()
  yhat_te[[j]] <- list()
  trainerr[[j]] <- list()
  testerr[[j]] <- list()
  nnz[[j]] <- list()
  for (i in "Genus"#level_names
  ) {
    cat(i, fill = TRUE)
    ytr <- dat_list[[i]]$y[tr[[j]]]
    yte <- dat_list[[i]]$y[-tr[[j]]]
    ztr <- log_pseudo(dat_list[[i]]$x[tr[[j]], ])
    zte <- log_pseudo(dat_list[[i]]$x[-tr[[j]], ])
    fit[[j]][[i]] <- trac(ztr, ytr, A = dat_list[[i]]$A, min_frac = 1e-3, nlam = 100)
    cvfit[[j]][[i]] <- cv_trac(fit[[j]][[i]], Z = ztr, y = ytr, A = dat_list[[i]]$A)
    yhat_tr[[j]][[i]] <- predict_trac(fit[[j]][[i]], new_Z = ztr)[[1]]
    yhat_te[[j]][[i]] <- predict_trac(fit[[j]][[i]], new_Z = zte)[[1]]
    trainerr[[j]][[i]] <- colMeans((yhat_tr[[j]][[i]] - ytr)^2)
    testerr[[j]][[i]] <- colMeans((yhat_te[[j]][[i]] - yte)^2)
    nnz[[j]][[i]] <- colSums(fit[[j]][[i]][[1]]$gamma != 0)
  }
}


#' second stage: run log-ratio lasso with interactions on selected aggregations from stage 1
#'
